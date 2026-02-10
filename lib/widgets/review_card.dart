import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/utils/number_utils.dart';

class ReviewCard extends StatefulWidget {
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
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  // ✅ 세션 동안 중복 조회수 증가 방지 (앱 종료 시 초기화됨)
  static final Set<String> _viewedIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final review = widget.review;

    return VisibilityDetector(
      key: Key('review-${review.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5 && !_viewedIds.contains(review.id)) {
          _viewedIds.add(review.id);
          // ✅ 서버로 조회수 증가 요청 (비동기, 결과 기다리지 않음)
          ReviewService.incrementViewCount(review.id);
        }
      },
      child: Container(
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
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: widget.onTapStore,
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
              onTap: widget.onTap,
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
                          onTap: widget.onTapProfile,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: (review.userProfileUrl != null && review.userProfileUrl!.isNotEmpty)
                                      ? NetworkImage(review.userProfileUrl!)
                                      : null,
                                  child: (review.userProfileUrl == null || review.userProfileUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 12, color: Colors.grey)
                                      : null,
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

                    // ✅ 3. 하단 아이콘 (우측 정렬, 순서: 좋아요 -> 댓글 -> 조회수)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // 우측 정렬
                      children: [
                        // 좋아요 (아이콘 + 숫자)
                        const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          NumberUtils.format(review.likeCount),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),

                        // 댓글 (아이콘 + 숫자)
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          NumberUtils.format(review.commentCount),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),

                        // 조회수 (아이콘 + 숫자)
                        const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          NumberUtils.format(review.viewCount),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}