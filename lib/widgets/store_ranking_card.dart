import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/core/search_trigger.dart';

class StoreRankingCard extends StatelessWidget {
  final StoreRanking ranking;
  final String sortOption;

  const StoreRankingCard({
    super.key,
    required this.ranking,
    required this.sortOption,
  });

  // ✅ 클릭 시 저장된 좌표로 즉시 이동
  void _handleStoreClick() {
    if (ranking.storeName.isNotEmpty) {
      // 좌표가 있으면 좌표로, 없으면 이름으로 검색
      if (ranking.storeLat != null && ranking.storeLng != null) {
        searchTrigger.value = SearchTarget(
          query: ranking.storeName,
          lat: ranking.storeLat,
          lng: ranking.storeLng,
        );
      } else {
        searchTrigger.value = SearchTarget(query: ranking.storeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 카드 디자인
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. 순위 (ShaderMask 적용)
          SizedBox(
            width: 40,
            child: _buildRankText(ranking.rank),
          ),

          // 2. 매장 사진 (클릭 시 이동)
          GestureDetector(
            onTap: _handleStoreClick,
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              // 이미지가 없으면 아이콘 표시
              child: const Icon(Icons.store_rounded, color: Colors.grey, size: 30),
            ),
          ),

          // 3. 매장 정보 (이름, 주소, 리뷰 수)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _handleStoreClick,
                  child: Text(
                    ranking.storeName,
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
                // 주소 (회색)
                if (ranking.storeAddress != null)
                  Text(
                    ranking.storeAddress!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                // 리뷰 수 (보라색 강조)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    children: [
                      const TextSpan(text: "리뷰 "),
                      TextSpan(
                        text: "${ranking.reviewCount}개",
                        style: const TextStyle(
                          color: Color(0xFF9C7CFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 4. 점수 및 신뢰도 (중앙 정렬)
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "니즈파인 점수",
                style: TextStyle(
                  color: Colors.purple[300],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ranking.avgScore.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF7C4DFF),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "신뢰도 ${ranking.avgTrust.toInt()}%",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 순위 텍스트 디자인 (금/은/동 그라데이션)
  Widget _buildRankText(int rank) {
    if (rank > 3) {
      return Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF424242),
          ),
        ),
      );
    }

    final List<Color> colors = (rank == 1)
        ? [const Color(0xFFFFD700), const Color(0xFFFFA000)] // Gold
        : (rank == 2)
        ? [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)] // Silver
        : [const Color(0xFFFFAB91), const Color(0xFFD84315)]; // Bronze

    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          '$rank',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}