// lib/models/ranking_models.dart

class Review {
  final String id;
  final String storeName;
  final String? storeAddress;
  final String reviewText;
  final double userRating;           // 1.0 ~ 5.0
  final double needsfineScore;       // 니즈파인 점수
  final int trustLevel;              // 신뢰도 (0~100)
  final bool authenticity;           // 진정성
  final bool advertisingWords;       // 광고성 여부
  final bool emotionalBalance;       // 감정 균형
  final List<String> tags;           // 태그 (최대 3개)
  final DateTime createdAt;
  final String? userId;

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
    required this.createdAt,
    this.userId,
  });

  // JSON 파싱
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
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'],
    );
  }
}

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
