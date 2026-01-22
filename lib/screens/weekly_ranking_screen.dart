// lib/screens/weekly_ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/widgets/store_ranking_card.dart'; // ✅ 공통 위젯 사용
import 'package:needsfine_app/core/search_trigger.dart';

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
      searchTrigger.value = SearchTarget(query: storeName.trim());
      Navigator.pop(context); // 홈으로 복귀
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
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
      // ✅ 데이터가 없을 때 빈 화면 처리 추가
      body: rankings.isEmpty
          ? const Center(
        child: Text(
          '랭킹 데이터가 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final ranking = rankings[index];
          final imageUrl = storeImageMap[ranking.storeName];

          return GestureDetector(
            onTap: () => _onStoreTap(context, ranking.storeName),
            // ✅ [핵심] StoreRankingCard 재사용으로 디자인 통일 & 오류 방지
            child: StoreRankingCard(
              ranking: ranking,
              sortOption: '니즈파인 순',
              imageUrl: imageUrl, // 이미지 전달
            ),
          );
        },
      ),
    );
  }
}