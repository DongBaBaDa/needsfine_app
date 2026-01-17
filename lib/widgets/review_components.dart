import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // 테마 컬러 참조
import 'package:needsfine_app/models/ranking_models.dart'; // 기존 모델 사용
import 'package:needsfine_app/screens/ranking_screen.dart'; // searchTrigger 접근용

// ==========================================
// 1. Review Card Widget (The Core UI)
// ==========================================
class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onTapStore; // 매장명 클릭 시 동작 (지도 이동)

  const ReviewCard({
    super.key,
    required this.review,
    this.onTapStore,
  });

  @override
  Widget build(BuildContext context) {
    // Visual Silence Colors
    const Color kBackground = Color(0xFFFFFDF9);
    const Color kPrimary = Color(0xFFC87CFF);
    const Color kTextMain = Colors.black87;
    final Color kTextSub = Colors.grey[600]!;

    return Container(
      color: kBackground, // Warm White 배경
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------
          // [Section A] Store Name (Navigation Link)
          // -------------------------------------------------------
          InkWell(
            onTap: onTapStore, // ✅ 클릭 시 '내 주변'으로 이동
            splashColor: kPrimary.withOpacity(0.1),
            highlightColor: kPrimary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  review.storeName,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 18,
                    fontWeight: FontWeight.w700, // Bold
                    color: Colors.black, // ✅ 검은색 (No decoration)
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
          if (review.storeAddress != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 12.0),
              child: Text(
                review.storeAddress!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            )
          else
            const SizedBox(height: 12),

          // -------------------------------------------------------
          // [Section B] User Header & Insight Logic
          // -------------------------------------------------------
          Row(
            children: [
              // 1. Avatar (Placeholder)
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: review.userEmail != null
                    ? null // 실제 구현 시 NetworkImage 사용
                    : null,
                child: const Icon(Icons.person, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 10),

              // 2. User Info & Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 닉네임 (ID 뒷자리 가림 처리 등)
                  Text(
                    review.userId?.substring(0, 5) ?? '익명 사용자', // 임시 닉네임 로직
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: kTextMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 별점 표시
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < review.userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFFFB800), // Amber
                          size: 14,
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        '${review.createdAt.year}.${review.createdAt.month}.${review.createdAt.day}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // 3. ★ Insight Logic (Quiet Advisor)
              _buildInsightChip(review, kPrimary),
            ],
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------
          // [Section C] Content (Text)
          // -------------------------------------------------------
          Text(
            review.reviewText,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 14,
              height: 1.6, // 줄간격 여유 있게
              color: kTextMain,
            ),
          ),

          // 태그가 있다면 표시
          if (review.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: review.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "#$tag",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                )).toList(),
              ),
            ),

          const SizedBox(height: 16),

          // -------------------------------------------------------
          // [Section D] Photos (Conditional)
          // -------------------------------------------------------
          if (review.photoUrls.isNotEmpty)
            Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.photoUrls[index],
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                    ),
                  );
                },
              ),
            ),

          // -------------------------------------------------------
          // [Section E] Footer (Actions) - Quiet Style
          // -------------------------------------------------------
          const Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
          Row(
            children: [
              _buildFooterButton(Icons.thumb_up_alt_outlined, "도움이 돼요 ${review.likeCount}"),
              const SizedBox(width: 16),
              _buildFooterButton(Icons.chat_bubble_outline_rounded, "댓글 0"),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                onPressed: () {}, // 공유 기능 추후 구현
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Insight Chip Builder
  Widget _buildInsightChip(Review review, Color primaryColor) {
    // 100점 만점을 5점 만점으로 변환하여 비교
    final double normalizedNeedsFineScore = review.needsfineScore > 5.0
        ? review.needsfineScore / 20.0
        : review.needsfineScore;

    final double diff = normalizedNeedsFineScore - review.userRating;

    if (diff >= 0.5) {
      // Case A: NeedsFine 점수가 더 높음 (겸손한 리뷰)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 12, color: primaryColor),
            const SizedBox(width: 4),
            Text(
              "만족도 높음",
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (diff <= -0.5) {
      // Case B: NeedsFine 점수가 더 낮음 (과장된 리뷰)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_down, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              "과장된 표현",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    // Case C: Neutral (Visual Silence)
    return const SizedBox.shrink();
  }

  // Helper: Footer Button
  Widget _buildFooterButton(IconData icon, String text) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}