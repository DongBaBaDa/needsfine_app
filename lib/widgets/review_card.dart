// lib/widgets/review_card.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

// ✅ 기능을 뺐으므로 StatelessWidget으로 변경 (성능 최적화)
class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onTap;       // 카드 전체 클릭 (상세 이동)
  final VoidCallback onTapStore;  // 매장명 클릭
  final VoidCallback onTapProfile;// 프로필 클릭

  const ReviewCard({
    super.key,
    required this.review,
    required this.onTap,
    required this.onTapStore,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 프로필 이미지 처리
    ImageProvider avatarImage;
    if (review.userProfileUrl != null && review.userProfileUrl!.isNotEmpty) {
      avatarImage = NetworkImage(review.userProfileUrl!);
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
          // 1. 상단 매장 정보 (클릭 시 이동)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // 텍스트 영역 (Expanded)
                Expanded(
                  child: Padding(
                    // ✅ [수정] 왼쪽 사진이 없으므로 왼쪽 여백을 없애고 오른쪽 여백만 유지
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: onTapStore,
                          child: Text(
                            review.storeName,
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
                          review.storeAddress ?? "",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // 점수 표시
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.needsFineScore,
                      style: TextStyle(
                        color: const Color(0xFF7C4DFF).withOpacity(0.55),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.needsfineScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: const Color(0xFF7C4DFF).withOpacity(0.92),
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${l10n.reliability} ${review.trustLevel}%",
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

          // 2. 본문 및 하단 정보 (카드 전체 클릭)
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 프로필
                  Row(
                    children: [
                      // ✅ 프로필 사진 + 닉네임만 클릭 가능
                      InkWell(
                        onTap: onTapProfile,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: avatarImage,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                review.nickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, size: 14, color: Colors.amber.withOpacity(0.4)),
                      const SizedBox(width: 2),
                      Text(
                        "${review.userRating}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),

                  // 태그 표시
                  if (review.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: review.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0E9FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "#$tag",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7C4DFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 리뷰 텍스트
                  Text(
                    review.reviewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  // 사진 미리보기
                  if (review.photoUrls.isNotEmpty)
                    Container(
                      height: 80,
                      margin: const EdgeInsets.only(top: 12),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: review.photoUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              review.photoUrls[index],
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

                  // ✅ 3. 하단 아이콘 (우측 정렬, 데이터 바인딩 수정)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // 우측 정렬
                    children: [
                      // 좋아요 (아이콘 + 숫자)
                      const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${review.likeCount}", // ✅ 모델 데이터 사용
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(width: 16),

                      // 저장 (아이콘 + 숫자)
                      const Icon(Icons.bookmark_border_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        // ✅ 모델에 saveCount가 있다면 연결, 없다면 0 처리
                        // (모델에 saveCount 필드가 없다면 추가해야 합니다)
                        "${review.saveCount ?? 0}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(width: 16),

                      // 댓글 (아이콘 + 숫자)
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${review.commentCount}", // ✅ 모델 데이터 사용
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(width: 16),

                      // 신고 버튼
                      const Icon(
                        Icons.campaign,
                        size: 18,
                        color: Colors.red,
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