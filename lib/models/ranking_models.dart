// lib/models/ranking_models.dart

/// 리뷰 데이터 모델
/// 웹 프로젝트의 SavedReview 인터페이스와 동일한 구조
class Review {
  final String id;
  final String storeName;
  final String? storeAddress;
  final String reviewText;
  final double userRating;           // 사용자가 준 별점 (0.5~5.0)
  final double needsfineScore;       // 니즈파인 점수
  final int trustLevel;              // 신뢰도 (0~100)
  final bool authenticity;           // 진정성
  final bool advertisingWords;       // 광고성 단어 사용 여부
  final bool emotionalBalance;       // 감정 균형
  final List<String> tags;           // 태그 (최대 3개)
  final List<String> photoUrls;      // 사진 URL 목록
  final bool isCritical;             // 비판적 리뷰 여부
  final bool isHidden;               // 숨김 처리 여부
  final DateTime createdAt;
  final String? userId;              // 작성자 ID (user_number)
  final String? userEmail;           // 작성자 이메일

  Review({
    required this.id,
    required this.storeName,
    this.storeAddress,
    required this.reviewText,
    required this.userRating,
    required this.needsfineScore,
    required this.trustLevel,
    required this.authenticity,
    required this.advertisingWords,
    required this.emotionalBalance,
    required this.tags,
    required this.photoUrls,
    required this.isCritical,
    required this.isHidden,
    required this.createdAt,
    this.userId,
    this.userEmail,
  });

  /// JSON → Dart 객체 변환
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'],
      reviewText: json['review_text'] ?? '',
      userRating: (json['user_rating'] ?? 3.0).toDouble(),
      needsfineScore: (json['needsfine_score'] ?? 70.0).toDouble(),
      trustLevel: (json['trust_level'] ?? 50).toInt(),
      authenticity: json['authenticity'] ?? false,
      advertisingWords: json['advertising_words'] ?? false,
      emotionalBalance: json['emotional_balance'] ?? false,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      photoUrls: (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      isCritical: json['is_critical'] ?? false,
      isHidden: json['is_hidden'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      userId: json['users']?['user_number'],
      userEmail: json['users']?['email'],
    );
  }

  /// Dart 객체 → JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_name': storeName,
      'store_address': storeAddress,
      'review_text': reviewText,
      'user_rating': userRating,
      'needsfine_score': needsfineScore,
      'trust_level': trustLevel,
      'authenticity': authenticity,
      'advertising_words': advertisingWords,
      'emotional_balance': emotionalBalance,
      'tags': tags,
      'photo_urls': photoUrls,
      'is_critical': isCritical,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 매장 순위 데이터 모델
class StoreRanking {
  final String storeName;
  final double avgScore;
  final int reviewCount;
  final double avgTrust;
  final int rank;
  final List<String>? topTags;

  StoreRanking({
    required this.storeName,
    required this.avgScore,
    required this.reviewCount,
    required this.avgTrust,
    required this.rank,
    this.topTags,
  });
}

/// 통계 데이터 모델
class Stats {
  final int total;
  final double average;
  final double avgTrust;

  Stats({
    required this.total,
    required this.average,
    required this.avgTrust,
  });
}

/// 피드백 데이터 모델
class Feedback {
  final String id;
  final String userId;
  final String? email;
  final String message;
  final DateTime createdAt;

  Feedback({
    required this.id,
    required this.userId,
    this.email,
    required this.message,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? '',
      userId: json['users']?['user_number'] ?? 'unknown',
      email: json['email'],
      message: json['message'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
