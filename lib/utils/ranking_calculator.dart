// lib/utils/ranking_calculator.dart
import 'package:needsfine_app/models/ranking_models.dart';

class RankingCalculator {
  // 매장 이름 정규화 (공백 제거 + 소문자 변환)
  static String normalizeStoreName(String name) {
    return name.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  // 매장별 순위 계산
  static List<StoreRanking> calculateStoreRankings(List<Review> reviews) {
    if (reviews.isEmpty) return [];

    // 매장별 데이터 그룹화
    Map<String, _StoreData> storeMap = {};

    for (var review in reviews) {
      final normalized = normalizeStoreName(review.storeName);
      
      if (!storeMap.containsKey(normalized)) {
        storeMap[normalized] = _StoreData(
          originalName: review.storeName,
          scores: [],
          trusts: [],
          tags: [],
        );
      }

      storeMap[normalized]!.scores.add(review.needsfineScore);
      storeMap[normalized]!.trusts.add(review.trustLevel.toDouble());
      storeMap[normalized]!.tags.addAll(review.tags);
    }

    // 순위 리스트 생성
    List<StoreRanking> rankings = storeMap.entries.map((entry) {
      final data = entry.value;
      
      // 태그 빈도수 계산
      Map<String, int> tagCount = {};
      for (var tag in data.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }

      // 상위 2개 태그 선택
      // [수정] 캐스케이드 연산자(..) 오류 수정
      // sort()는 void를 반환하므로, 리스트를 먼저 정렬하고 그 리스트를 사용해야 합니다.
      List<MapEntry<String, int>> sortedTags = tagCount.entries.toList();
      sortedTags.sort((a, b) => b.value.compareTo(a.value));

      List<String> topTags = sortedTags
          .take(2)
          .map((e) => e.key)
          .toList();

      return StoreRanking(
        storeName: data.originalName,
        avgScore: data.scores.reduce((a, b) => a + b) / data.scores.length,
        reviewCount: data.scores.length,
        avgTrust: data.trusts.reduce((a, b) => a + b) / data.trusts.length,
        rank: 0, // 정렬 후 할당
        topTags: topTags.isEmpty ? null : topTags,
      );
    }).toList();

    // 평균 점수 기준 내림차순 정렬
    rankings.sort((a, b) => b.avgScore.compareTo(a.avgScore));

    // 순위 할당
    for (int i = 0; i < rankings.length; i++) {
      rankings[i] = StoreRanking(
        storeName: rankings[i].storeName,
        avgScore: rankings[i].avgScore,
        reviewCount: rankings[i].reviewCount,
        avgTrust: rankings[i].avgTrust,
        rank: i + 1,
        topTags: rankings[i].topTags,
      );
    }

    return rankings;
  }
}

// 내부 데이터 클래스
class _StoreData {
  final String originalName;
  final List<double> scores;
  final List<double> trusts;
  final List<String> tags;

  _StoreData({
    required this.originalName,
    required this.scores,
    required this.trusts,
    required this.tags,
  });
}
