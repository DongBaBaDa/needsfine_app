import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';

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

  final Color _primaryColor = const Color(0xFFC87CFF);
  final Color _backgroundColor = const Color(0xFFFFFDF9);

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _fetchComments();
    _checkLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkOwnership() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId != null && widget.review.userId == currentUserId) {
      if (mounted) setState(() => _isOwner = true);
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

  // ✅ 좋아요 토글
  Future<void> _toggleLike() async {
    try {
      // UI 즉시 반영 (Optimistic)
      setState(() => _isLiked = !_isLiked);

      // 서버 요청
      await ReviewService.toggleLike(widget.review.id);
    } catch (e) {
      // 실패시 롤백
      if (mounted) {
        setState(() => _isLiked = !_isLiked);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
      }
    }
  }

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
      _fetchComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("댓글 등록 실패: $e")));
    }
  }

  // ✅ 리뷰 삭제: 서버에서 지워질 때까지 기다렸다가 pop
  Future<void> _onDeletePressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("정말로 리뷰를 삭제하시겠습니까? 복구할 수 없습니다."),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("리뷰가 삭제되었습니다.")));
          // true를 반환해야 목록 화면(RankingScreen)에서 새로고침함
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
      }
    }
  }

  // ✅ 리뷰 수정: 수정 완료 후 돌아오면 갱신
  void _onEditPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          reviewToEdit: widget.review,
        ),
      ),
    );

    // 수정 화면에서 true를 들고 돌아왔다면 (수정 성공)
    if (result == true && mounted) {
      Navigator.pop(context, true); // 상세화면을 닫고 목록을 새로고침
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
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildUserInfo(),
                  const SizedBox(height: 12),
                  _buildBadges(),
                  const SizedBox(height: 32),
                  Text(
                    widget.review.reviewText,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),
                  if (widget.review.photoUrls.isNotEmpty) _buildPhotos(),
                  if (widget.review.tags.isNotEmpty)
                    Wrap(spacing: 8.0, runSpacing: 8.0, children: widget.review.tags.map((tag) => _buildTag(tag)).toList()),
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _toggleLike,
                      icon: Icon(
                        _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 18,
                        color: _isLiked ? Colors.white : _primaryColor,
                      ),
                      label: Text(
                        "도움이 됐어요",
                        style: TextStyle(
                          color: _isLiked ? Colors.white : _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _isLiked ? _primaryColor : Colors.white,
                        side: BorderSide(color: _primaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const Divider(height: 64, thickness: 1, color: Color(0xFFEEEEEE)),
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
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

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
              onPressed: _submitComment,
              icon: Icon(Icons.send, color: _primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}