// lib/screens/review_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';
// ✅ 비속어 필터 임포트
import 'package:needsfine_app/core/profanity_filter.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class ReviewDetailScreen extends StatefulWidget {
  final Review review;
  const ReviewDetailScreen({super.key, required this.review});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();

  bool _isOwner = false;
  bool _isLoadingComments = true;
  List<Map<String, dynamic>> _comments = [];
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isReported = false;

  // ✅ 유저 프로필 상태 관리 (홈에서 안 넘어왔을 경우 대비)
  late String _nickname;
  String? _userProfileUrl;
  String? _myNickname; // ✅ 내 닉네임 (알림용)

  // 디자인 토큰
  static const Color _brand = Color(0xFF8A2BE2);
  static const Color _bg = Color(0xFFF2F2F7);

  @override
  void initState() {
    super.initState();
    // 초기값 설정
    _nickname = widget.review.nickname;
    _userProfileUrl = widget.review.userProfileUrl;

    _checkOwnership();
    _fetchComments();
    _checkLikeStatus();
    _checkSaveStatus();
    _checkReportStatus();
    _checkAndFetchProfile(); // ✅ 프로필 누락 확인 및 로드
    _fetchMyProfile(); // ✅ 내 정보 로드
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    try {
      await ReviewService.incrementViewCount(widget.review.id);
    } catch (e) {
      debugPrint("조회수 증가 실패: $e");
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ✅ 프로필 정보가 비어있다면 다시 가져오는 안전장치 로직
  Future<void> _checkAndFetchProfile() async {
    if ((_nickname.isEmpty || _nickname == 'Unknown') && widget.review.userId != null) {
      try {
        final data = await _supabase
            .from('profiles')
            .select('nickname, profile_image_url')
            .eq('id', widget.review.userId!)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            _nickname = data['nickname'] ?? '익명';
            _userProfileUrl = data['profile_image_url'];
          });
        }
      } catch (e) {
        debugPrint("프로필 보완 로드 실패: $e");
      }
    }
  }

  Future<void> _checkOwnership() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null && widget.review.userId == currentUserId) {
      if (mounted) setState(() => _isOwner = true);
    }
  }

  // ✅ 내 닉네임 가져오기
  Future<void> _fetchMyProfile() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      final data = await _supabase.from('profiles').select('nickname').eq('id', myId).maybeSingle();
      if (data != null) {
        _myNickname = data['nickname'];
      }
    } catch (e) {
      debugPrint("내 프로필 로드 실패: $e");
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles(nickname, profile_image_url)')
          .eq('review_id', widget.review.id)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('댓글 로드 실패: $e');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _checkLikeStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final res = await _supabase
        .from('review_votes')
        .select()
        .eq('review_id', widget.review.id)
        .eq('user_id', userId)
        .eq('vote_type', 'like')
        .maybeSingle();

    if (mounted) setState(() => _isLiked = res != null);
  }

  Future<void> _checkSaveStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await _supabase
          .from('review_saves')
          .select('id')
          .eq('review_id', widget.review.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) setState(() => _isSaved = res != null);
    } catch (e) {
      debugPrint('저장 상태 확인 실패: $e');
    }
  }

  Future<void> _checkReportStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await _supabase
          .from('reports')
          .select('id')
          .eq('reported_content_id', widget.review.id)
          .eq('reporter_id', userId)
          .maybeSingle();

      if (mounted) setState(() => _isReported = res != null);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _toggleSave() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      }
      return;
    }

    final next = !_isSaved;
    setState(() => _isSaved = next);

    try {
      if (next) {
        await _supabase.from('review_saves').upsert(
          {'user_id': userId, 'review_id': widget.review.id},
          onConflict: 'user_id,review_id',
        );
      } else {
        await _supabase.from('review_saves').delete().eq('user_id', userId).eq('review_id', widget.review.id);
      }
    } catch (e) {
      if (mounted) setState(() => _isSaved = !next);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 처리 중 오류가 발생했습니다.")));
      }
    }
  }

  // ✅ [수정됨] 충돌(Duplicate Key) 방지를 위한 안전한 로직 적용
  Future<void> _toggleLike() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    // 1. 현재 상태 백업 (에러 시 복구용)
    final wasLiked = _isLiked;

    // 2. 화면 선반영 (Optimistic Update)
    setState(() => _isLiked = !wasLiked);

    try {
      if (wasLiked) {
        // 3-A. 이미 좋아요 상태였다면 -> 취소 (Delete)
        await _supabase
            .from('review_votes')
            .delete()
            .eq('user_id', userId)
            .eq('review_id', widget.review.id);
      } else {
        // 3-B. 좋아요가 아니었다면 -> 등록 (Upsert)
        // ✅ Insert 대신 Upsert를 사용하여 이미 존재할 경우 에러(23505)를 방지하고 덮어씀
        await _supabase.from('review_votes').upsert(
          {
            'user_id': userId,
            'review_id': widget.review.id,
            'vote_type': 'like',
          },
          onConflict: 'user_id,review_id', // DB의 Unique Key 제약조건 컬럼
        );

        // ✅ 좋아요 알림 전송 (내가 쓴 글이 아닐 때만)
        if (widget.review.userId != null && widget.review.userId != userId && _myNickname != null) {
           try {
             final l10n = AppLocalizations.of(context)!;
             await _supabase.from('notifications').insert({
               'receiver_id': widget.review.userId,
               'type': 'like',
               'reference_id': widget.review.id.toString(), // review ID
               'title': l10n.notificationLikeTitle,
               'content': l10n.notificationLikeContent(_myNickname!, widget.review.storeName),
             });
           } catch (e) {
             debugPrint("알림 전송 실패: $e");
           }
        }
      }
    } catch (e) {
      // 4. 실패 시 롤백
      debugPrint("❌ 좋아요 처리 에러: $e");
      if (mounted) {
        setState(() => _isLiked = wasLiked);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
      }
    }
  }

  // ... inside _ReviewDetailScreenState

  void _onReportPressed() {
    final l10n = AppLocalizations.of(context)!;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginRequired)));
      return;
    }

    if (_isReported) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.alreadyReported)));
      return;
    }

    final reasonList = [
      l10n.reportReason1,
      l10n.reportReason2,
      l10n.reportReason3,
      l10n.reportReason4,
      l10n.reportReason5,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(l10n.report, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("신고 사유에 해당하는 항목을 선택해주세요.", style: TextStyle(fontSize: 13, color: Colors.grey)), // TODO: Localize this description if needed
              ),
              const SizedBox(height: 10),
              ...reasonList.map((reason) => ListTile(
                title: Text(reason, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(reason);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport(String reason) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isReported = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      await _supabase.from('reports').insert({
        'reporter_id': userId,
        'reported_content_id': widget.review.id,
        'content_type': 'review',
        'reason': reason,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
      }
    } catch (e) {
      debugPrint("신고 전송 실패: $e");
      if (mounted) setState(() => _isReported = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("신고 전송 실패: $e")));
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (ProfanityFilter.hasProfanity(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("바른 말을 사용해주세요. 비속어가 감지되었습니다."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginRequired)));
      return;
    }

    try {
      await _supabase.from('comments').insert({
        'review_id': widget.review.id,
        'user_id': userId,
        'content': text,
      });

      // ✅ 댓글 알림 전송 (내가 쓴 글이 아닐 때만)
      if (widget.review.userId != null && widget.review.userId != userId && _myNickname != null) {
          try {
            await _supabase.from('notifications').insert({
              'receiver_id': widget.review.userId,
              'type': 'comment',
              'reference_id': widget.review.id.toString(), // review ID
              'title': l10n.notificationCommentTitle,
              'content': l10n.notificationCommentContent(_myNickname!, text),
            });
          } catch (e) {
             debugPrint("댓글 알림 전송 실패: $e");
          }
      }

      _commentController.clear();
      FocusScope.of(context).unfocus();
      _fetchComments();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("댓글 등록 실패: $e")));
    }
  }

  Future<void> _onDeletePressed() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAction, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReviewService.deleteReview(widget.review.id);
      if (mounted) {
        Navigator.pop(context, true); // 삭제 후 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
      }
    }
  }

  void _onEditPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(reviewToEdit: widget.review),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _navigateToMap() {
    if (widget.review.storeName.isNotEmpty) {
      searchTrigger.value = SearchTarget(
        query: widget.review.storeName,
        lat: widget.review.storeLat,
        lng: widget.review.storeLng,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 전체 배경을 흰색으로 통일하여 분절감 제거
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _isOwner
            ? [
          IconButton(icon: const Icon(Icons.edit_rounded, size: 22, color: Colors.grey), onPressed: _onEditPressed),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Colors.red), onPressed: _onDeletePressed),
        ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 매장 정보 헤더 (박스 없이 시원하게 배치)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStoreHeader(),
                  ),

                  // 2. 구분선 (부드러운 분리)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  ),

                  // 3. 유저 정보 & 별점
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildUserInfo(l10n),
                  ),

                  const SizedBox(height: 20),

                  // 4. 리뷰 내용 (텍스트 + 사진)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBadges(l10n),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text("${l10n.viewCount} ${widget.review.viewCount}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 본문 텍스트
                        Text(
                          widget.review.reviewText,
                          style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                        ),
                        const SizedBox(height: 24),

                        // 사진
                        if (widget.review.photoUrls.isNotEmpty) _buildPhotos(),

                        // 태그
                        if (widget.review.tags.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: widget.review.tags.map((tag) => _buildTag(tag)).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 5. 액션 버튼 (좋아요/저장/신고) - 구분선 위
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          label: l10n.helpful,
                          isActive: _isLiked,
                          icon: _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                          activeColor: _brand,
                          onTap: _toggleLike,
                        ),
                        _buildActionButton(
                          label: l10n.save,
                          isActive: _isSaved,
                          icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          activeColor: _brand,
                          onTap: _toggleSave,
                        ),
                        _buildActionButton(
                          label: l10n.report,
                          isActive: _isReported,
                          icon: Icons.campaign_rounded,
                          activeColor: Colors.red,
                          onTap: _onReportPressed,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 6. 두꺼운 구분선 (섹션 분리)
                  Container(height: 8, color: _bg),

                  // 7. 댓글 섹션
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${l10n.comments} ${_comments.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        _isLoadingComments
                            ? const Center(child: CircularProgressIndicator(color: _brand))
                            : _comments.isEmpty
                            ? Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(child: Text(l10n.noComments, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))),
                        )
                            : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final profile = comment['profiles'] ?? {};
                            final user = profile['nickname'] ?? '알 수 없는 유저';
                            final text = comment['content'] ?? '';
                            final profileUrl = profile['profile_image_url'];
                            final userId = comment['user_id'];
                            final commentId = comment['id'].toString();
                            final isMine = userId != null && userId == _supabase.auth.currentUser?.id;

                            return _buildCommentItem(commentId, user, text, profileUrl, userId, isMine);
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _navigateToMap,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  widget.review.storeName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black, height: 1.2),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.review.storeName.isNotEmpty)
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (widget.review.storeAddress != null)
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.review.storeAddress!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildUserInfo(AppLocalizations l10n) {
    return Row(
      children: [
        InkWell(
          onTap: () {
            if (widget.review.userId != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.review.userId!)));
            }
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[100],
            backgroundImage: (_userProfileUrl != null && _userProfileUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(_userProfileUrl!)
                : null,
            child: (_userProfileUrl == null || _userProfileUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey, size: 20)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 위젯 속성 대신 로컬 상태 _nickname 사용
            Text(_nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              '${widget.review.createdAt.year}.${widget.review.createdAt.month}.${widget.review.createdAt.day}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l10n.userRating, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)), // ✅ 라벨 추가
            const SizedBox(height: 2),
            StarRating(rating: widget.review.userRating, size: 18),
          ],
        ),
      ],
    );
  }

  Widget _buildBadges(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildBadgeTag(l10n.needsFine, widget.review.needsfineScore.toStringAsFixed(1), _brand),
        _buildBadgeTag(l10n.trustScore, '${widget.review.trustLevel}%', Colors.blueGrey),
      ],
    );
  }

  Widget _buildBadgeTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: "$label ", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text("#$tag", style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPhotos() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.review.photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: widget.review.photoUrls[index],
              fit: BoxFit.cover,
              width: 220,
              placeholder: (context, url) => Container(color: Colors.grey[100]),
              errorWidget: (context, url, error) => Container(color: Colors.grey[100], child: const Icon(Icons.error, color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isActive,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isActive ? activeColor : Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey[500],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(String commentId, String user, String text, String? profileUrl, String? userId, bool isMine) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (userId != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));
            }
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                ? CachedNetworkImageProvider(profileUrl)
                : null,
            child: (profileUrl == null || profileUrl.isEmpty)
                ? const Icon(Icons.person, size: 16, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (userId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));
                      }
                    },
                    child: Text(user.isEmpty ? l10n.unknownUser : user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const Spacer(),
                  if (isMine)
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'edit') _editComment(commentId, text);
                          if (value == 'delete') _deleteComment(commentId);
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text(l10n.edit),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(l10n.deleteAction, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ 댓글 수정
  Future<void> _editComment(String commentId, String oldText) async {
    final controller = TextEditingController(text: oldText);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("댓글 수정", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "내용을 입력하세요"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != oldText) {
                try {
                  await _supabase.from('comments').update({'content': newText}).eq('id', commentId);
                  _fetchComments(); // 목록 갱신
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글이 수정되었습니다.")));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 실패")));
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("저장", style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ✅ 댓글 삭제
  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("댓글 삭제"),
        content: const Text("정말로 이 댓글을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('comments').delete().eq('id', commentId);
        _fetchComments(); // 목록 갱신
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글이 삭제되었습니다.")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "따뜻한 댓글을 남겨주세요...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _submitComment,
              icon: const Icon(Icons.send_rounded, color: _brand),
            ),
          ],
        ),
      ),
    );
  }
}