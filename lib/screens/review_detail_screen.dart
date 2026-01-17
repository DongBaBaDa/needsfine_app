import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ 이미지 캐싱 패키지
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/screens/ranking_screen.dart'; // searchTrigger 접근용
import 'package:needsfine_app/core/needsfine_theme.dart'; // 테마 컬러 사용
import 'package:needsfine_app/core/search_trigger.dart';


class ReviewDetailScreen extends StatefulWidget {
  final Review review;
  const ReviewDetailScreen({super.key, required this.review});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  bool _isOwner = false;
  bool _isDeleteActive = false; // 삭제 버튼 활성화 상태 (빨간색)
  final TextEditingController _commentController = TextEditingController(); // ✅ 댓글 입력 컨트롤러

  final Color _primaryColor = const Color(0xFFC87CFF);
  final Color _backgroundColor = const Color(0xFFFFFDF9);

  // 더미 댓글 데이터 (추후 API 연동 필요)
  final List<Map<String, String>> _dummyComments = [
    {"user": "사용자123", "text": "좋은 정보 감사합니다!"},
    {"user": "맛집탐방러", "text": "여기 웨이팅 길었나요?"},
  ];

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkOwnership() async {
    final currentUserId = await ReviewService.getUserId();
    if (currentUserId != null && widget.review.userId == currentUserId) {
      if (mounted) setState(() => _isOwner = true);
    }
  }

  // 삭제 버튼 클릭 시 로직
  void _onDeletePressed() {
    setState(() {
      _isDeleteActive = true; // 빨간색으로 변경
    });
    _showDeleteDialog();
  }

  Future<void> _showDeleteDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("삭제 확인", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("정말로 삭제하시겠습니까?"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                setState(() => _isDeleteActive = false); // 취소 시 회색 복구
              },
              child: const Text("취소", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ReviewService.deleteReview(widget.review.id);
      if (success && mounted) {
        Navigator.pop(context, true); // 목록 새로고침을 위해 true 반환
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("리뷰가 삭제되었습니다.")));
      }
    }
  }

  void _onEditPressed() {
    // 수정 기능 구현 시 WriteReviewScreen으로 데이터를 넘겨 재사용 권장
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 기능 준비중입니다.")));
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.1), height: 1.0),
        ),
      ),
      // ✅ Column으로 변경하여 스크롤 영역과 고정 영역(댓글 입력창) 분리
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: Store Name & Date
                  Row(
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
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'NotoSansKR',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                                ],
                              ),
                              if (widget.review.storeAddress != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    widget.review.storeAddress!,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        '${widget.review.createdAt.year}.${widget.review.createdAt.month}.${widget.review.createdAt.day} '
                            '${widget.review.createdAt.hour.toString().padLeft(2, '0')}:${widget.review.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. User Info & Rating
                  Row(
                    children: [
                      // ✅ 프로필 이미지 캐싱 적용
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
                      Text(
                        widget.review.nickname,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      StarRating(rating: widget.review.userRating, size: 20),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // NeedsFine Badges
                  Row(children: [
                    _buildBadge('니즈파인', widget.review.needsfineScore.toStringAsFixed(1), true),
                    const SizedBox(width: 8),
                    _buildBadge('신뢰도', '${widget.review.trustLevel}%', false),
                  ]),

                  const SizedBox(height: 32),

                  // 3. Review Content
                  Text(
                    widget.review.reviewText,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 4. Photos (✅ CachedNetworkImage 적용)
                  if (widget.review.photoUrls.isNotEmpty) ...[
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
                              placeholder: (context, url) => Container(
                                  width: 200,
                                  color: Colors.grey[200],
                                  child: const Center(child: CircularProgressIndicator())
                              ),
                              errorWidget: (context, url, error) => Container(
                                  width: 200,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error)
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // 5. Tags
                  if (widget.review.tags.isNotEmpty)
                    Wrap(spacing: 8.0, runSpacing: 8.0, children: widget.review.tags.map((tag) => _buildTag(tag)).toList()),

                  const Divider(height: 48, thickness: 1, color: Color(0xFFEEEEEE)),

                  // 6. Comments Section
                  const Text("댓글", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Dummy Comments Render
                  ..._dummyComments.map((comment) => _buildCommentItem(comment['user']!, comment['text']!)),

                  const SizedBox(height: 40),

                  // 7. Edit/Delete Actions (Owner Only)
                  if (_isOwner)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 수정 버튼
                        TextButton.icon(
                          onPressed: _onEditPressed,
                          icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                          label: const Text("수정", style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        // 삭제 버튼
                        TextButton.icon(
                          onPressed: _onDeletePressed,
                          icon: Icon(Icons.delete, size: 18, color: _isDeleteActive ? Colors.red : Colors.grey),
                          label: Text("삭제", style: TextStyle(color: _isDeleteActive ? Colors.red : Colors.grey, fontWeight: _isDeleteActive ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ],
                    ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),

          // ✅ [New] 댓글 입력창 (화면 하단 고정)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))
              ],
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        // TODO: 실제 댓글 전송 로직 구현 필요
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글 등록 기능은 준비중입니다.")));
                        _commentController.clear();
                        FocusScope.of(context).unfocus(); // 키보드 내리기
                      }
                    },
                    icon: Icon(Icons.send, color: _primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String value, bool isPrimary) {
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

  Widget _buildCommentItem(String user, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 16, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }
}