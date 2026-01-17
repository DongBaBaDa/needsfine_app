import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';

// ✅ 전역 검색 트리거 (RankingScreen과 공유)
import 'package:needsfine_app/screens/ranking_screen.dart';

class StoreRankingCard extends StatelessWidget {
  final StoreRanking ranking;
  final String sortOption; // '니즈파인 순' or '사용자 별점 순'

  const StoreRankingCard({
    super.key,
    required this.ranking,
    required this.sortOption,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTopRank = ranking.rank <= 3;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: isTopRank ? const BoxDecoration(color: Color(0xFF9C7CFF), shape: BoxShape.circle) : null,
          child: Center(
            child: Text('${ranking.rank}',
                style: TextStyle(
                    color: isTopRank ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () {
                // 전역 검색 트리거 작동
                searchTrigger.value = ranking.storeName;
              },
              child: Text(ranking.storeName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      decoration: TextDecoration.none
                  )),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(sortOption == '니즈파인 순' ? '평균 ${ranking.avgScore.toStringAsFixed(1)}점' : '별점 ${ranking.avgUserRating.toStringAsFixed(1)}점',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Text('리뷰 ${ranking.reviewCount}개', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
        ),
      ]),
    );
  }
}