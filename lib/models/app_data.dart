import 'package:needsfine_app/services/score_calculator.dart';

// -----------------------------------------------------------------------------
// 1. Review 모델
// -----------------------------------------------------------------------------
class Review {
  final String userName;
  final String content;
  final double rating;
  final String date;

  // ✅ [추가] 리뷰 작성 시점의 위치 정보 박제
  final String? address;
  final double? latitude;
  final double? longitude;

  // 계산된 속성들
  late final double needsfineScore;
  late final int trustLevel;
  late final bool authenticity;
  late final bool isCritical;
  late final bool isHidden;
  late final List<String> tags;

  Review({
    required this.userName,
    required this.content,
    required this.rating,
    required this.date,
    this.address,   // 추가
    this.latitude,  // 추가
    this.longitude, // 추가
    bool hasPhoto = false,
  }) {
    final scoreResult = ScoreCalculator.calculateNeedsFineScore(content, rating, hasPhoto);
    needsfineScore = (scoreResult['needsfine_score'] as num).toDouble();
    trustLevel = scoreResult['trust_level'] as int;
    tags = List<String>.from(scoreResult['tags'] ?? []);
    authenticity = trustLevel >= 70;
    isCritical = (needsfineScore < 3.0 && trustLevel >= 50);
    isHidden = (trustLevel < 20);
  }
}

// -----------------------------------------------------------------------------
// 2. Store 모델
// -----------------------------------------------------------------------------
class Store {
  final String id;
  final String name;
  final String category;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final String address; // ✅ 주소 필드 명시

  double userRating;
  double needsFineScore;
  int reviewCount;
  final String? summary;

  List<Review> reviews;

  Store({
    required this.id,
    required this.name,
    required this.category,
    required this.tags,
    required this.latitude,
    required this.longitude,
    required this.address, // 필수값 변경
    this.userRating = 0.0,
    this.needsFineScore = 0.0,
    this.reviewCount = 0,
    this.summary,
    required this.reviews,
  });
}

// -----------------------------------------------------------------------------
// 3. AppData
// -----------------------------------------------------------------------------
class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  List<Store> stores = [];

  // ✅ [수정] 리뷰 추가 시 위치 정보까지 함께 저장
  void addReview(String storeName, String content, double rating, String address, double lat, double lng) {
    try {
      // 1. 이미 등록된 가게인지 확인 (이름과 위치로 매칭)
      // 실제로는 DB ID로 해야 하지만 베타 단계에선 이름+위치 근사치로 판단
      Store store;
      try {
        store = stores.firstWhere((s) => s.name == storeName && (s.latitude - lat).abs() < 0.001);
      } catch (e) {
        // 없으면 새 가게 생성 (임시 ID)
        store = Store(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: storeName,
          category: '기타', // 카테고리는 검색 정보에서 받아와야 함
          tags: [],
          latitude: lat,
          longitude: lng,
          address: address,
          reviews: [],
        );
        stores.add(store);
      }

      final newReview = Review(
        userName: "니즈파인(User)",
        content: content,
        rating: rating,
        date: DateTime.now().toIso8601String().substring(0, 10),
        address: address,   // 저장
        latitude: lat,      // 저장
        longitude: lng,     // 저장
        hasPhoto: false,
      );

      store.reviews.insert(0, newReview);
      _updateStoreScores(store);

    } catch (e) {
      print("Error adding review: $e");
    }
  }

  void _updateStoreScores(Store store) {
    if (store.reviews.isEmpty) {
      store.userRating = 0;
      store.needsFineScore = 0;
      store.reviewCount = 0;
      return;
    }
    store.reviewCount = store.reviews.length;
    store.userRating = store.reviews.map((r) => r.rating).reduce((a, b) => a + b) / store.reviewCount;
    store.needsFineScore = store.reviews.map((r) => r.needsfineScore).reduce((a, b) => a + b) / store.reviewCount;
  }
}