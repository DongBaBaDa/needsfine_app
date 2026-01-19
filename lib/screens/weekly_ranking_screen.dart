// lib/screens/weekly_ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/core/search_trigger.dart'; // ✅ SearchTarget 임포트

class WeeklyRankingScreen extends StatelessWidget {
  final List<StoreRanking> rankings;
  final Map<String, String> storeImageMap;

  const WeeklyRankingScreen({
    super.key,
    required this.rankings,
    required this.storeImageMap,
  });

  void _onStoreTap(BuildContext context, String storeName) {
    if (storeName.trim().isNotEmpty) {
      // ✅ [유지] SearchTarget 객체로 감싸서 전달
      searchTrigger.value = SearchTarget(query: storeName.trim());

      // 홈 화면의 탭 전환을 위해 현재 화면(더보기 화면)을 닫음
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // 기존 배경색 유지
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '주간 니즈파인 랭킹',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: rankings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ranking = rankings[index];
          // 이미지가 있으면 쓰고, 없으면 빈 문자열 (카드 내부에서 처리)
          final imageUrl = storeImageMap[ranking.storeName] ?? '';

          return _WeeklyListCard(
            ranking: ranking,
            imageUrl: imageUrl,
            onTap: () => _onStoreTap(context, ranking.storeName),
          );
        },
      ),
    );
  }
}

// ✅ [디자인 수정] StoreRankingCard 스타일 적용
class _WeeklyListCard extends StatelessWidget {
  final StoreRanking ranking;
  final String imageUrl;
  final VoidCallback onTap;

  const _WeeklyListCard({
    required this.ranking,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // ✅ StoreRankingCard 스타일: 흰 배경, 둥근 모서리, 부드러운 그림자
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

            // 2. [좌측] 매장 아이콘 (이미지가 있으면 이미지, 없으면 회색 아이콘)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // 연한 회색 배경
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              )
                  : const Icon(
                Icons.store_outlined, // 매장 아이콘
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

                  // 주소 (없으면 생략)
                  if (ranking.address != null && ranking.address!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ranking.address!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888), // 연한 회색
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 6),

                  // 별점 및 리뷰 개수
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
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
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
                const Text(
                  '니즈파인 점수',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9C7CFF), // 보라색
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),

                // 점수 (크게)
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

                // 신뢰도
                Text(
                  '신뢰도 ${ranking.avgTrust.toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666), // 진한 회색
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}