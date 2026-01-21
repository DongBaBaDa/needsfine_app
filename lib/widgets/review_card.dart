// lib/widgets/review_card.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';

// ✅ 다국어 패키지 임포트
import 'package:needsfine_app/l10n/app_localizations.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback onTap;        // 리뷰 상세 이동
  final VoidCallback onTapStore;   // ✅ 가게 이동 (SearchTrigger는 바깥에서 처리)
  final VoidCallback onTapProfile; // 유저 프로필 이동

  const ReviewCard({
    super.key,
    required this.review,
    required this.onTap,
    required this.onTapStore,
    required this.onTapProfile,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isLiked = false;
  int _likeCount = 0;

  // ✅ 저장 상태 + 저장 수
  bool _isSaved = false;
  int _saveCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.review.likeCount;
    _checkInitialLikeStatus();
    _checkInitialSaveStatus();
    _loadInitialSaveCount();
  }

  Future<void> _checkInitialLikeStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final res = await Supabase.instance.client
        .from('review_votes')
        .select()
        .eq('review_id', widget.review.id)
        .eq('user_id', userId)
        .eq('vote_type', 'like')
        .maybeSingle();
    if (mounted && res != null) setState(() => _isLiked = true);
  }

  // ✅ 저장 상태 초기 로드
  Future<void> _checkInitialSaveStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await Supabase.instance.client
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

  // ✅ 저장 수 로드 (북마크 옆 숫자)
  Future<void> _loadInitialSaveCount() async {
    try {
      final rows = await Supabase.instance.client
          .from('review_saves')
          .select('id')
          .eq('review_id', widget.review.id);

      final c = (rows is List) ? rows.length : 0;
      if (mounted) setState(() => _saveCount = c);
    } catch (e) {
      debugPrint('저장 수 로드 실패: $e');
      if (mounted) setState(() => _saveCount = 0);
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      if (_likeCount < 0) _likeCount = 0;
    });
    // API 연동 로직은 기존 유지
  }

  // ✅ 저장 토글 + 저장 수 반영
  Future<void> _toggleSave() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        // "로그인이 필요합니다" (키가 없어서 하드코딩 유지)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인이 필요합니다.")),
        );
      }
      return;
    }

    final next = !_isSaved;

    // optimistic UI
    setState(() {
      _isSaved = next;
      _saveCount += next ? 1 : -1;
      if (_saveCount < 0) _saveCount = 0;
    });

    try {
      if (next) {
        await Supabase.instance.client.from('review_saves').upsert(
          {
            'user_id': userId,
            'review_id': widget.review.id,
          },
          onConflict: 'user_id,review_id',
        );
      } else {
        await Supabase.instance.client
            .from('review_saves')
            .delete()
            .eq('user_id', userId)
            .eq('review_id', widget.review.id);
      }
    } catch (e) {
      // 롤백
      if (mounted) {
        setState(() {
          _isSaved = !next;
          _saveCount += next ? -1 : 1;
          if (_saveCount < 0) _saveCount = 0;
        });
      }
      debugPrint('저장 토글 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("저장 처리 중 오류가 발생했습니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ l10n 객체 가져오기
    final l10n = AppLocalizations.of(context)!;

    ImageProvider avatarImage;
    if (widget.review.userProfileUrl != null && widget.review.userProfileUrl!.isNotEmpty) {
      avatarImage = NetworkImage(widget.review.userProfileUrl!);
    } else {
      avatarImage = const AssetImage('assets/images/default_profile.png');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onTapStore, // ✅ 홈스크린 로직과 동일: 밖에서 SearchTrigger 처리
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store, color: Colors.grey),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: widget.onTapStore, // ✅
                          child: Text(
                            widget.review.storeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.review.storeAddress ?? "",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.avgNeedsFineScore, // "평균 니즈파인 점수" (혹은 "니즈파인 점수")
                      style: TextStyle(
                        color: const Color(0xFF7C4DFF).withOpacity(0.55),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.review.needsfineScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: const Color(0xFF7C4DFF).withOpacity(0.92),
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${l10n.reliability} ${widget.review.trustLevel}%", // "신뢰도 XX%"
                      style: const TextStyle(
                        color: Color(0xFF6B6B6F),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[100]),

          InkWell(
            onTap: widget.onTap,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: widget.onTapProfile,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: avatarImage,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.review.nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.star, size: 14, color: Colors.amber.withOpacity(0.4)),
                        const SizedBox(width: 2),
                        Text(
                          "${widget.review.userRating}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.review.reviewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  if (widget.review.photoUrls.isNotEmpty)
                    Container(
                      height: 80,
                      margin: const EdgeInsets.only(top: 12),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.review.photoUrls.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.review.photoUrls[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(width: 80, color: Colors.grey[200]),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                              size: 14,
                              color: _isLiked ? const Color(0xFF7C4DFF) : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$_likeCount",
                              style: TextStyle(
                                fontSize: 12,
                                color: _isLiked ? const Color(0xFF7C4DFF) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // ✅ 저장: 아이콘 + 숫자만
                      InkWell(
                        onTap: _toggleSave,
                        child: Row(
                          children: [
                            Icon(
                              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              size: 14,
                              color: _isSaved ? const Color(0xFF7C4DFF) : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$_saveCount",
                              style: TextStyle(
                                fontSize: 12,
                                color: _isSaved ? const Color(0xFF7C4DFF) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${widget.review.commentCount}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}