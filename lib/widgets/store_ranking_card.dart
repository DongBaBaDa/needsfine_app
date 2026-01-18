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

  @override
  Widget build(BuildContext context) {
    Color? rankColor;
    if (ranking.rank == 1) rankColor = const Color(0xFFFFD700);
    else if (ranking.rank == 2) rankColor = const Color(0xFFC0C0C0);
    else if (ranking.rank == 3) rankColor = const Color(0xFFCD7F32);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // ✅ [수정] SearchTarget 객체 전달
          searchTrigger.value = SearchTarget(query: ranking.storeName);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor ?? Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${ranking.rank}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rankColor != null ? Colors.white : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ranking.storeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '리뷰 ${ranking.reviewCount}개',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sortOption == '니즈파인 순'
                        ? '${ranking.avgScore.toStringAsFixed(1)}점'
                        : '${ranking.avgUserRating.toStringAsFixed(1)}점',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C7CFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (sortOption == '니즈파인 순')
                    Text(
                      '신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: ranking.avgTrust >= 70 ? Colors.green : Colors.orange,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}