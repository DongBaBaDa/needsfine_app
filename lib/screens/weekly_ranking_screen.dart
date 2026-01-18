import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/widgets/store_ranking_card.dart';

class WeeklyRankingScreen extends StatelessWidget {
  final List<StoreRanking> rankings;
  final Map<String, String> storeImageMap;

  const WeeklyRankingScreen({
    super.key,
    required this.rankings,
    required this.storeImageMap,
  });

  void _goToMap(BuildContext context, String storeName) {
    if (storeName.trim().isEmpty) return;
    searchTrigger.value = storeName.trim();

    // 이 화면 닫고 -> MainShell로 복귀하면 MainShell 리스너가 Nearby 탭으로 넘김
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: const Text('주간 니즈파인 랭킹', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: rankings.isEmpty
          ? const Center(child: Text('데이터가 없습니다.'))
          : ListView.separated(
        itemCount: rankings.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
        itemBuilder: (context, index) {
          final r = rankings[index];

          // ✅ 너가 좋아한 순위 오르락내리락 표시: StoreRankingCard가 이미 구현되어있다고 가정하고 그대로 사용
          // ✅ 추가로 "탭하면 지도 검색" 기능 부여하려면 StoreRankingCard 안에 onTap이 없다면,
          //    이 GestureDetector로 감싸는 방식이 가장 안전함(기존 위젯 수정 최소).
          return GestureDetector(
            onTap: () => _goToMap(context, r.storeName),
            child: StoreRankingCard(
              ranking: r,
              sortOption: '니즈파인 순',
            ),
          );
        },
      ),
    );
  }
}
