import 'dart:math';

// 1. 리뷰 모델
class Review {
  final String userName;
  final String content;
  final double rating;
  final String date;
  final double needsfineScore;
  final int trustLevel;
  final bool authenticity;
  final bool advertisingWords;
  final bool emotionalBalance;

  Review({
    required this.userName,
    required this.content,
    required this.rating,
    required this.date,
    required this.needsfineScore,
    required this.trustLevel,
    required this.authenticity,
    required this.advertisingWords,
    required this.emotionalBalance,
  });
}

// 2. 가게 모델 ( [수정] 위도/경도 필드 추가 )
class Store {
  final String id;
  final String name;
  final String category;
  final List<String> tags;
  final double latitude;  // 가게 위도
  final double longitude; // 가게 경도
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

// 3. [전역 데이터]
class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  List<Store> stores = [
    Store(
      id: '1',
      name: "족발야시장 강남점",
      category: "족발·보쌈",
      tags: ["맛있는", "친절한", "푸짐한", "깨끗한", "가성비"],
      latitude: 37.5013,  // [수정] 강남역 근처 실제 좌표
      longitude: 127.025, // [수정] 강남역 근처 실제 좌표
      userRating: 4.5,
      needsFineScore: 88.5,
      reviewCount: 120,
      reviews: [],
    ),
    Store(
      id: '2',
      name: "엽기떡볶이 본점",
      category: "분식",
      tags: ["매운", "스트레스", "중독성", "빠른", "배달"],
      latitude: 37.5755,  // [수정] 동대문 근처 실제 좌표
      longitude: 127.028, // [수정] 동대문 근처 실제 좌표
      userRating: 4.8,
      needsFineScore: 92.0,
      reviewCount: 350,
      reviews: [],
    ),
  ];

  List<Map<String, dynamic>> myReviews = [];

  void addReview(String storeId, String content, double rating, Map<String, dynamic> scoreData) {
    final store = stores.firstWhere((s) => s.id == storeId);
    final newReview = Review(
      userName: "니즈파인",
      content: content,
      rating: rating,
      date: DateTime.now().toString().split(' ')[0],
      needsfineScore: scoreData['needsfine_score'] as double,
      trustLevel: scoreData['trust_level'] as int,
      authenticity: scoreData['authenticity'] as bool,
      advertisingWords: scoreData['advertising_words'] as bool,
      emotionalBalance: scoreData['emotional_balance'] as bool,
    );
    store.reviews.insert(0, newReview);
    store.reviewCount++;
    myReviews.insert(0, {
      "storeName": store.name,
      "content": content,
      "rating": rating,
      "date": newReview.date,
      "needsfineScore": newReview.needsfineScore,
    });
    _updateStoreScores(store);
  }

  void _updateStoreScores(Store store) {
    if (store.reviews.isEmpty) {
      store.userRating = 0;
      store.needsFineScore = 0;
      return;
    }
    double totalRating = store.reviews.fold(0, (sum, r) => sum + r.rating);
    store.userRating = totalRating / store.reviewCount;
    double totalNeedsFineScore = store.reviews.fold(0, (sum, r) => sum + r.needsfineScore);
    store.needsFineScore = totalNeedsFineScore / store.reviewCount;
  }
}
