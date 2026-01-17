import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/screens/ranking_screen.dart'; // searchTrigger 접근용

class ReviewDetailScreen extends StatefulWidget {
  final Review review;
  const ReviewDetailScreen({super.key, required this.review});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  bool _isOwner = false;
  final Color _primaryColor = const Color(0xFFC87CFF);
  final Color _backgroundColor = const Color(0xFFFFFDF9);

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final currentUserId = await ReviewService.getUserId();
    // 데이터 보호: Null Check 강화
    if (currentUserId != null && widget.review.userId == currentUserId) {
      if (mounted) setState(() => _isOwner = true);
    }
  }

  Future<void> _deleteReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("리뷰 삭제", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("정말로 이 리뷰를 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("취소", style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ReviewService.deleteReview(widget.review.id);
      if (success && mounted) {
        Navigator.pop(context, true); // true 리턴 -> 목록 새로고침
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("리뷰가 삭제되었습니다.")));
      }
    }
  }

  // 매장 이름 클릭 시 '내 주변' 지도 탭으로 이동
  void _navigateToMap() {
    if (widget.review.storeName.isNotEmpty) {
      // 1. 전역 트리거 발동
      searchTrigger.value = widget.review.storeName;
      // 2. 현재 상세 화면 닫기 (MainShell이 트리거를 감지하여 탭을 전환함)
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
      body: SingleChildScrollView(
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
                    borderRadius: BorderRadius.circular(4),
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
                                  color: Colors.black, // ✅ 검은색 (No decoration)
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
                  '${widget.review.createdAt.year}.${widget.review.createdAt.month}.${widget.review.createdAt.day}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. Scores & Insight Chip
            Row(
              children: [
                StarRating(rating: widget.review.userRating, size: 20),
                const SizedBox(width: 12),
                // Insight Logic 호출
                _buildInsightChip(),
              ],
            ),

            const SizedBox(height: 16),

            // NeedsFine Badges
            Row(children: [
              _buildBadge(
                  label: '니즈파인',
                  value: widget.review.needsfineScore.toStringAsFixed(1),
                  isPrimary: true
              ),
              const SizedBox(width: 8),
              _buildBadge(
                  label: '신뢰도',
                  value: '${widget.review.trustLevel}%',
                  isPrimary: false
              ),
            ]),

            const SizedBox(height: 32),

            // 3. Review Content (Full Text)
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

            // 4. Photos
            if (widget.review.photoUrls.isNotEmpty) ...[
              SizedBox(
                height: 200, // 상세 화면이므로 사진을 더 크게
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.review.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.review.photoUrls[index],
                        fit: BoxFit.cover,
                        width: 200,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 5. Tags
            if (widget.review.tags.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.review.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E9FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                    ),
                  ),
                )).toList(),
              ),

            // Bottom Spacer
            const SizedBox(height: 100),
          ],
        ),
      ),

      // Edit/Delete Buttons (Owner Only)
      floatingActionButton: _isOwner ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'edit',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("수정 기능은 준비 중입니다.")));
            },
            backgroundColor: Colors.white,
            elevation: 2,
            mini: true,
            child: Icon(Icons.edit, color: _primaryColor),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'delete',
            onPressed: _deleteReview,
            backgroundColor: _primaryColor,
            elevation: 2,
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ) : null,
    );
  }

  // Logic B: The Quiet Advisor 구현
  Widget _buildInsightChip() {
    final double normalizedScore = widget.review.needsfineScore > 5.0
        ? widget.review.needsfineScore / 20.0
        : widget.review.needsfineScore;

    final double diff = normalizedScore - widget.review.userRating;

    if (diff >= 0.5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "✨ 글의 만족도가 더 높아요",
          style: TextStyle(
            color: _primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (diff <= -0.5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "📉 과장된 표현이 있어요",
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox(); // Visual Silence
  }

  Widget _buildBadge({required String label, required String value, required bool isPrimary}) {
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
          Text(label, style: TextStyle(
            color: isPrimary ? Colors.white : Colors.grey[600],
            fontSize: 12,
          )),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(
            color: isPrimary ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}