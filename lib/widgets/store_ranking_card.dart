import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/core/search_trigger.dart';

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
    // 1~3위 여부 확인
    final bool isTopRank = ranking.rank <= 3;

    return Container(
      // ✅ 1~3위는 옅은 니즈파인 색 배경, 나머지는 흰색
      decoration: BoxDecoration(
        color: isTopRank ? const Color(0xFFF0E9FF) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 순위 표시 영역 (원형 제거, 숫자만 강조)
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  '${ranking.rank}',
                  style: TextStyle(
                    // 1~3위는 보라색, 나머지는 검은색
                    color: isTopRank ? const Color(0xFF9C7CFF) : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontStyle: isTopRank ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 정보 표시 영역
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        // 전역 검색 트리거 작동
                        searchTrigger.value = ranking.storeName;
                      },
                      child: Text(
                          ranking.storeName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.none
                          )
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                            sortOption == '니즈파인 순'
                                ? '니즈파인 ${ranking.avgScore.toStringAsFixed(1)}점'
                                : '별점 ${ranking.avgUserRating.toStringAsFixed(1)}점',
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9C7CFF),
                                fontWeight: FontWeight.bold
                            )
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '리뷰 ${ranking.reviewCount}개',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)
                        ),
                      ],
                    ),
                  ]
              ),
            ),
          ]
      ),
    );
  }
}