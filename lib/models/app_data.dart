import 'dart:math';

// 1. 리뷰 모델 (서버 로직에 맞춰 필드 수정)
class Review {
  final String userName;
  final String content;
  final double rating; // 사용자가 입력한 별점
  final String date;

  // calculateNeedsFineScore 함수에서 계산된 값들
  final double needsfineScore; // 최종 니즈파인 점수 (별점 * 신뢰도)
  final int trustLevel; // 신뢰도 레벨 (0-100)
  final bool authenticity; // 진정성
  final bool advertisingWords; // 광고성 단어 포함 여부
  final bool emotionalBalance; // 감정적 균형

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

// 2. 가게 모델
class Store {
  final String id;
  final String name;
  final String category;
  final List<String> tags;
  double userRating;      // 리뷰들의 평점 평균
  double needsFineScore;  // 리뷰들의 니즈파인 점수 평균
  int reviewCount;
  List<Review> reviews;

  Store({
    required this.id,
    required this.name,
    required this.category,
    required this.tags,
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
      userRating: 4.8,
      needsFineScore: 92.0,
      reviewCount: 350,
      reviews: [],
    ),
  ];

  List<Map<String, dynamic>> myReviews = [];

  // --- [🔥 새로운 리뷰 등록 및 점수 계산 로직] ---
  void addReview(String storeId, String content, double rating, Map<String, dynamic> scoreData) {
    final store = stores.firstWhere((s) => s.id == storeId);

    // 1. 리뷰 객체 생성 (scoreData에서 값 추출)
    final newReview = Review(
      userName: "니즈파인", // 현재 로그인한 유저
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

    // 2. 내 리뷰 목록에도 추가 (상세 정보 포함)
    myReviews.insert(0, {
      "storeName": store.name,
      "content": content,
      "rating": rating,
      "date": newReview.date,
      "needsfineScore": newReview.needsfineScore,
    });

    // 3. 가게 점수(별점, 니즈파인 지수) 전체 평균으로 업데이트
    _updateStoreScores(store);
  }

  // 점수 업데이트 로직 (전체 평균 계산 방식으로 변경)
  void _updateStoreScores(Store store) {
    if (store.reviews.isEmpty) {
      store.userRating = 0;
      store.needsFineScore = 0;
      return;
    }

    // 1. 별점 평균 재계산
    double totalRating = store.reviews.fold(0, (sum, r) => sum + r.rating);
    store.userRating = totalRating / store.reviewCount;

    // 2. 니즈파인 지수 평균 재계산
    double totalNeedsFineScore = store.reviews.fold(0, (sum, r) => sum + r.needsfineScore);
    store.needsFineScore = totalNeedsFineScore / store.reviewCount;
  }
}
