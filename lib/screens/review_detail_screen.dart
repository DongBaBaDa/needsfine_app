import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/screens/ranking_screen.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/screens/write_review_screen.dart'; // 수정 화면용

class ReviewDetailScreen extends StatefulWidget {
  final Review review;
  const ReviewDetailScreen({super.key, required this.review});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();

  bool _isOwner = false; // 리뷰 작성자인지 여부
  bool _isLoadingComments = true;
  List<Map<String, dynamic>> _comments = []; // 실제 댓글 데이터

  final Color _primaryColor = const Color(0xFFC87CFF);
  final Color _backgroundColor = const Color(0xFFFFFDF9);

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 1. 리뷰 작성자 확인 (수정/삭제 버튼 노출용)
  Future<void> _checkOwnership() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null && widget.review.userId == currentUserId) {
      if (mounted) setState(() => _isOwner = true);
    }
  }

  // 2. 댓글 목록 불러오기 (DB 연동)
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

  // 3. 댓글 작성 로직
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    try {
      await _supabase.from('comments').insert({
        'review_id': widget.review.id,
        'user_id': userId,
        'content': text,
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();
      _fetchComments(); // 목록 새로고침
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("댓글 등록 실패: $e")));
    }
  }

  // 4. 리뷰 삭제 로직
  Future<void> _onDeletePressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("정말로 리뷰를 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ReviewService.deleteReview(widget.review.id);
        if (mounted) {
          Navigator.pop(context, true); // 목록 화면으로 돌아가며 갱신 신호 보냄
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("리뷰가 삭제되었습니다.")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  // 5. 리뷰 수정 로직 (화면 이동)
  void _onEditPressed() async {
    // WriteReviewScreen에 기존 데이터를 전달하도록 수정 필요 (현재는 단순히 이동만)
    // 실제로는 WriteReviewScreen 생성자에 review 객체를 받아서 초기값을 세팅해줘야 함
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 기능은 WriteReviewScreen 업데이트가 필요합니다.")));
  }

  void _navigateToMap() {
    if (widget.review.storeName.isNotEmpty) {
      searchTrigger.value = widget.review.storeName;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('리뷰 상세', style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: _isOwner
            ? [
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
            onPressed: _onEditPressed,
            tooltip: '수정',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: _onDeletePressed,
            tooltip: '삭제',
          ),
        ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 기존 UI 유지 (헤더, 유저 정보, 배지 등) ---
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildUserInfo(),
                  const SizedBox(height: 12),
                  _buildBadges(),
                  const SizedBox(height: 32),

                  // 본문
                  Text(
                    widget.review.reviewText,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),

                  // 사진
                  if (widget.review.photoUrls.isNotEmpty) _buildPhotos(),

                  // 태그
                  if (widget.review.tags.isNotEmpty)
                    Wrap(spacing: 8.0, runSpacing: 8.0, children: widget.review.tags.map((tag) => _buildTag(tag)).toList()),

                  const Divider(height: 48, thickness: 1, color: Color(0xFFEEEEEE)),

                  // --- 댓글 영역 ---
                  Text("댓글 ${_comments.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  _isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("첫 번째 댓글을 남겨보세요!", style: TextStyle(color: Colors.grey))),
                  )
                      : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final profile = comment['profiles'];
                      return _buildCommentItem(
                        profile?['nickname'] ?? '익명',
                        comment['content'] ?? '',
                        profile?['profile_image_url'],
                      );
                    },
                  ),
                  const SizedBox(height: 60), // 하단 입력창 가림 방지
                ],
              ),
            ),
          ),

          // 댓글 입력창
          _buildCommentInput(),
        ],
      ),
    );
  }

  // --- 위젯 분리 메서드들 ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: _navigateToMap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.review.storeName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                  ],
                ),
                if (widget.review.storeAddress != null)
                  Text(widget.review.storeAddress!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ),
        Text(
          '${widget.review.createdAt.year}.${widget.review.createdAt.month}.${widget.review.createdAt.day}',
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[200],
          backgroundImage: (widget.review.userProfileUrl != null && widget.review.userProfileUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(widget.review.userProfileUrl!)
              : null,
          child: (widget.review.userProfileUrl == null || widget.review.userProfileUrl!.isEmpty)
              ? const Icon(Icons.person, color: Colors.grey, size: 20)
              : null,
        ),
        const SizedBox(width: 10),
        Text(widget.review.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        StarRating(rating: widget.review.userRating, size: 20),
      ],
    );
  }

  Widget _buildBadges() {
    return Row(children: [
      _buildBadgeTag('니즈파인', widget.review.needsfineScore.toStringAsFixed(1), true),
      const SizedBox(width: 8),
      _buildBadgeTag('신뢰도', '${widget.review.trustLevel}%', false),
    ]);
  }

  Widget _buildBadgeTag(String label, String value, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? _primaryColor : Colors.white,
        border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: isPrimary ? Colors.white : Colors.grey[600], fontSize: 12)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: isPrimary ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF0E9FF), borderRadius: BorderRadius.circular(20)),
      child: Text(tag, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
    );
  }

  Widget _buildPhotos() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.review.photoUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.review.photoUrls[index],
                  fit: BoxFit.cover,
                  width: 200,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCommentItem(String user, String text, String? profileUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[200],
            backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
            child: profileUrl == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "댓글을 입력하세요...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _submitComment, // ✅ 실제 전송 로직 연결
              icon: Icon(Icons.send, color: _primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}