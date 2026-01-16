// lib/models/ranking_models.dart

/// 리뷰 데이터 모델
class Review {
  final String id;
  final String storeName;
  final String? storeAddress;
  final String reviewText;
  final double userRating;
  final double needsfineScore;
  final int trustLevel;
  final bool authenticity;
  final bool advertisingWords;
  final bool emotionalBalance;
  final List<String> tags;
  final List<String> photoUrls;
  final bool isCritical;
  final bool isHidden;
  final DateTime createdAt;
  final String? userId;
  final String? userEmail;

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

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'],
      reviewText: json['review_text'] ?? '',
      userRating: (json['user_rating'] is num) ? (json['user_rating'] as num).toDouble() : 3.0,
      needsfineScore: (json['needsfine_score'] is num) ? (json['needsfine_score'] as num).toDouble() : 70.0,
      trustLevel: (json['trust_level'] ?? 50).toInt(),
      authenticity: json['authenticity'] ?? false,
      advertisingWords: json['advertising_words'] ?? false,
      emotionalBalance: json['emotional_balance'] ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isCritical: json['is_critical'] ?? false,
      isHidden: json['is_hidden'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      userId: json['users']?['user_number'],
      userEmail: json['users']?['email'],
    );
  }

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
  final double avgScore;      // 니즈파인 평균 점수
  final double avgUserRating; // ✅ 사용자 평균 별점 (필드 유지)
  final int reviewCount;
  final double avgTrust;
  final int rank;
  final List<String>? topTags;

  StoreRanking({
    required this.storeName,
    required this.avgScore,
    required this.avgUserRating, // ✅ 생성자 포함
    required this.reviewCount,
    required this.avgTrust,
    required this.rank,
    this.topTags,
  });

  // ✅ 서버(View) 데이터에서 변환하기 위한 팩토리 생성자 추가
  factory StoreRanking.fromViewJson(Map<String, dynamic> json, int rankIndex) {
    return StoreRanking(
      storeName: json['store_name'] ?? '알 수 없음',
      avgScore: (json['avg_score'] is num) ? (json['avg_score'] as num).toDouble() : 0.0,
      avgUserRating: (json['avg_user_rating'] is num) ? (json['avg_user_rating'] as num).toDouble() : 0.0,
      avgTrust: (json['avg_trust'] is num) ? (json['avg_trust'] as num).toDouble() : 0.0,
      reviewCount: (json['review_count'] is num) ? (json['review_count'] as num).toInt() : 0,
      rank: rankIndex,
      topTags: [], // View에서는 태그 가져오기가 복잡하므로 일단 빈 리스트
    );
  }
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
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}