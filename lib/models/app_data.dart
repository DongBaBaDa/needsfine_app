import 'package:needsfine_app/services/score_calculator.dart';

// -----------------------------------------------------------------------------
// 1. Review 모델
// -----------------------------------------------------------------------------
class Review {
  final String userName;
  final String content;
  final double rating;
  final String date;

  // 위치 정보 박제
  final String? address;
  final double? latitude;
  final double? longitude;

  // 사진 리스트
  final List<String> photoUrls;

  // 계산된 속성
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
    this.address,
    this.latitude,
    this.longitude,
    this.photoUrls = const [], // 기본값 빈 리스트
  }) {
    // 사진 유무에 따라 가산점 로직 적용
    final scoreResult = ScoreCalculator.calculateNeedsFineScore(content, rating, photoUrls.isNotEmpty);

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
  final String address;

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
    required this.address,
    this.userRating = 0.0,
    this.needsFineScore = 0.0,
    this.reviewCount = 0,
    required this.reviews,
  });

  // ✅ [핵심 추가] 이 가게의 모든 리뷰 사진을 모아서 반환 (최신순)
  List<String> get allPhotos {
    final photos = <String>[];
    for (var review in reviews) {
      photos.addAll(review.photoUrls);
    }
    return photos;
  }

  // ✅ [핵심 추가] 평균 신뢰도 계산
  int get averageTrustLevel {
    if (reviewCount == 0) return 0;
    final totalTrust = reviews.fold(0, (sum, item) => sum + item.trustLevel);
    return (totalTrust / reviewCount).round();
  }
}

// -----------------------------------------------------------------------------
// 3. AppData
// -----------------------------------------------------------------------------
class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  List<Store> stores = [];

  // ✅ [수정] 사진 URL 리스트까지 받도록 변경
  void addReview({
    required String storeName,
    required String content,
    required double rating,
    required String address,
    required double lat,
    required double lng,
    required List<String> photoUrls,
    String category = '음식점', // 기본 카테고리
  }) {
    try {
      // 1. 이미 등록된 가게인지 확인 (이름 + 좌표 근사치 매칭)
      Store store;
      try {
        store = stores.firstWhere(
                (s) => s.name == storeName && (s.latitude - lat).abs() < 0.0005 && (s.longitude - lng).abs() < 0.0005
        );
      } catch (e) {
        // 없으면 새 가게 생성
        store = Store(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: storeName,
          category: category,
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
        address: address,
        latitude: lat,
        longitude: lng,
        photoUrls: photoUrls,
      );

      store.reviews.insert(0, newReview); // 최신 리뷰가 위로
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