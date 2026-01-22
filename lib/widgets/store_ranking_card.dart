// lib/widgets/store_ranking_card.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/l10n/app_localizations.dart'; // 다국어 패키지

class StoreRankingCard extends StatelessWidget {
  final StoreRanking ranking;
  final String sortOption;
  final String? imageUrl; // ✅ 이미지가 있는 경우를 위해 추가 (선택 사항)

  const StoreRankingCard({
    super.key,
    required this.ranking,
    required this.sortOption,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 1. 순위별 메달 색상 설정
    Color rankColor;
    if (ranking.rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (ranking.rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (ranking.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.grey[300]!;
    }

    return Container(
      // ✅ 카드 디자인: 흰색 배경 + 둥근 모서리 + 그림자
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. [좌측] 순위
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${ranking.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. [좌측] 매장 아이콘 (이미지가 있으면 표시, 없으면 아이콘)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl!, fit: BoxFit.cover),
            )
                : const Icon(
              Icons.store_outlined,
              color: Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // 3. [중앙] 매장 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 매장 이름
                Text(
                  ranking.storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // ✅ 주소 표시 (DB 정보 반영)
                if (ranking.address != null && ranking.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ranking.address!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 6),

                // 별점 및 리뷰 수
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      ranking.avgUserRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '(${ranking.reviewCount})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. [우측] 니즈파인 점수 & 신뢰도
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.avgNeedsFineScore, // "평균 니즈파인 점수"
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9C7CFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ranking.avgScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9C7CFF),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.reliability} ${ranking.avgTrust.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}