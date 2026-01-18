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
      // ✅ [수정] SearchTarget 객체로 감싸서 전달
      searchTrigger.value = SearchTarget(query: storeName.trim());

      // 홈 화면의 탭 전환을 위해 현재 화면(더보기 화면)을 닫음
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '주간 니즈파인 랭킹',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rankings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final ranking = rankings[index];
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
    // 1~3위 뱃지 색상
    Color? rankBadgeColor;
    if (ranking.rank == 1) rankBadgeColor = const Color(0xFFFFD700); // Gold
    else if (ranking.rank == 2) rankBadgeColor = const Color(0xFFC0C0C0); // Silver
    else if (ranking.rank == 3) rankBadgeColor = const Color(0xFFCD7F32); // Bronze
    else rankBadgeColor = Colors.grey[200]; // 4위 이하는 회색

    Color rankTextColor = (ranking.rank <= 3) ? Colors.white : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // 1. 순위 뱃지 + 이미지
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[100],
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rankBadgeColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${ranking.rank}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rankTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // 2. 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 점수 뱃지들
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ScoreBadge(
                        label: 'NF ${ranking.avgScore.toStringAsFixed(1)}',
                        color: kNeedsFinePurple,
                        textColor: Colors.white,
                      ),
                      _ScoreBadge(
                        label: '신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%',
                        color: Colors.grey[100]!,
                        textColor: Colors.grey[700]!,
                      ),
                    ],
                  ),

                  if (ranking.topTags != null && ranking.topTags!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      ranking.topTags!.take(2).join(' · '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _ScoreBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}