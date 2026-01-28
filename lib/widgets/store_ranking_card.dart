// lib/widgets/store_ranking_card.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/l10n/app_localizations.dart'; // 다국어 패키지

class StoreRankingCard extends StatelessWidget {
  final StoreRanking ranking;
  final String sortOption;
  final String? imageUrl;

  const StoreRankingCard({
    super.key,
    required this.ranking,
    required this.sortOption,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 1. 순위별 색상 및 스타일 설정 (세련된 메탈릭 컬러)
    Color rankColor;
    double rankSize;
    if (ranking.rank == 1) {
      rankColor = const Color(0xFFFFB800); // Vivid Gold
      rankSize = 24.0;
    } else if (ranking.rank == 2) {
      rankColor = const Color(0xFFA0A0A0); // Deep Silver
      rankSize = 22.0;
    } else if (ranking.rank == 3) {
      rankColor = const Color(0xFFA05F2D); // Deep Bronze
      rankSize = 22.0;
    } else {
      rankColor = Colors.grey[400]!; // Light Grey
      rankSize = 18.0;
    }

    return Container(
      // 카드 디자인: 흰색 배경 + 둥근 모서리 + 그림자
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. [좌측] 순위 (타이포그래피 스타일, 아이콘 제거됨)
          SizedBox(
            width: 32, // 숫자 너비 고정 (정렬 맞춤)
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ❌ 아이콘 제거됨 (숫자만 깔끔하게 표시)
                Text(
                  '${ranking.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.w900, // 가장 두꺼운 폰트
                    fontStyle: FontStyle.italic, // 기울임꼴로 속도감 부여
                    fontSize: rankSize,
                    height: 1.0,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 2. [중앙] 매장 정보 (Expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 매장 이름
                Text(
                  ranking.storeName,
                  style: const TextStyle(
                    fontSize: 16, // 16포인트 유지
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 주소 표시
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
                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      ranking.avgUserRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${ranking.reviewCount})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. [우측] 니즈파인 점수 & 신뢰도
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
                  fontSize: 26, // 숫자 강조
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9C7CFF),
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${l10n.reliability} ${ranking.avgTrust.toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}