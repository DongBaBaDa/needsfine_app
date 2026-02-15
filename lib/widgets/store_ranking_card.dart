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
                const SizedBox(height: 6),
                _buildTierBadge(ranking),
              ],
            ),
          ),


          // 3. [우측] 니즈파인 점수 & 신뢰도
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.needsFineScore,
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
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9C7CFF),
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: Text(
                  '${l10n.reliability} ${ranking.avgTrust.toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // ✅ 거리 표시 (신뢰도 아래로 이동)
              if (ranking.distance != null) ...[
                const SizedBox(height: 4),
                Text(
                  "${ranking.distance!.toStringAsFixed(1)}km",
                  style: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF9C7CFF)
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildTierBadge(StoreRanking ranking) {
    String? label;
    Color color;
    bool isCandidate = ranking.avgTrust <= 65;

    // 1. Determine Base Tier
    if (ranking.avgScore >= 4.5) {
      label = "웨이팅 맛집";
      color = const Color(0xFF9C7CFF); // Theme Purple for highest tier
    } else if (ranking.avgScore >= 4.0) {
      label = "지역 맛집";
      color = const Color(0xFFCE93D8); // Light Purple for Local Spot
    } else if (ranking.avgScore >= 3.5) {
      label = "실패없는 식당";
      color = const Color(0xFF00BFA5); // Teal Accent
    } else if (ranking.avgScore >= 3.0) {
      label = "괜찮은 집";
      color = const Color(0xFFFFAB00); // Amber Accent
    } else {
      return const SizedBox.shrink(); // No badge for low scores
    }

    // 2. Adjust for Candidate Status
    if (isCandidate) {
      label = "$label 후보";
      color = const Color(0xFF9E9E9E); // Grey
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Light background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1), // Colored border
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color, // Colored text matching border
        ),
      ),
    );
  }
}