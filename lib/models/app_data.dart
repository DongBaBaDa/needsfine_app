import 'package:needsfine_app/utils/score_calculator.dart';

class Review {
  final String userName;
  final String content;
  final double rating;
  final String date;
  late final double needsfineScore;
  late final int trustLevel;
  late final bool authenticity;
  late final bool advertisingWords;
  late final bool isCritical;
  late final bool isHidden;
  late final List<String> tags;

  Review({
    required this.userName,
    required this.content,
    required this.rating,
    required this.date,
  }) {
    final scoreResult = calculateNeedsFineScore(content, rating);
    needsfineScore = scoreResult['needsfine_score'];
    trustLevel = scoreResult['trust_level'];
    tags = scoreResult['tags'];
    isCritical = scoreResult['is_critical'];
    isHidden = scoreResult['is_hidden'];
    authenticity = trustLevel >= 70;
    advertisingWords = false;
  }
}

class Store {
  final String id;
  final String name;
  final String category;
  final List<String> tags;
  final double latitude;
  final double longitude;
  double userRating;
  double needsFineScore;
  int reviewCount;
  List<Review> reviews;

  Store({
    required this.id,
    required this.name,
    required this.category,
    required this.tags,
    required this.latitude,
    required this.longitude,
    this.userRating = 0.0,
    this.needsFineScore = 0.0,
    this.reviewCount = 0,
    required this.reviews,
  });
}

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  List<Store> stores = [
    Store(id: '1', name: "족발야시장 강남점", category: "족발·보쌈", tags: ["맛있는"], latitude: 37.5013, longitude: 127.025, reviews: []),
    Store(id: '2', name: "엽기떡볶이 본점", category: "분식", tags: ["매운"], latitude: 37.5755, longitude: 127.028, reviews: []),
  ];

  // [복원 및 수정] addReview 메서드
  void addReview(String storeId, String content, double rating) {
    try {
      final store = stores.firstWhere((s) => s.id == storeId);
      final newReview = Review(
        userName: "니즈파인(User)", // 임시 사용자 이름
        content: content,
        rating: rating,
        date: DateTime.now().toIso8601String().substring(0, 10),
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
