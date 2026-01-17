import 'package:intl/intl.dart';

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
  final int likeCount;

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
    this.likeCount = 0,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    try {
      return Review(
        id: json['id']?.toString() ?? '',
        storeName: json['store_name']?.toString() ?? '',
        storeAddress: json['store_address']?.toString(),
        reviewText: json['review_text']?.toString() ?? '',
        userRating: (json['user_rating'] as num?)?.toDouble() ?? 3.0,
        needsfineScore: (json['needsfine_score'] as num?)?.toDouble() ?? 70.0,
        trustLevel: (json['trust_level'] as num?)?.toInt() ?? 50,
        authenticity: json['authenticity'] == true,
        // ✅ 에러 해결: 변수명을 advertisingWords로 일치시켰습니다.
        advertisingWords: json['advertising_words'] == true,
        emotionalBalance: json['emotional_balance'] == true,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        photoUrls: (json['photo_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isCritical: json['is_critical'] == true,
        isHidden: json['is_hidden'] == true,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
        userId: json['users'] != null ? json['users']['user_number']?.toString() : json['user_id']?.toString(),
        userEmail: json['users'] != null ? json['users']['email']?.toString() : null,
        likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      print("❌ Review 파싱 중 에러 발생: $e");
      return Review(
        id: 'error',
        storeName: '데이터 오류',
        reviewText: '',
        userRating: 0,
        needsfineScore: 0,
        trustLevel: 0,
        authenticity: false,
        advertisingWords: false,
        emotionalBalance: false,
        tags: [],
        photoUrls: [],
        isCritical: false,
        isHidden: false,
        createdAt: DateTime.now(),
        likeCount: 0,
      );
    }
  }
}

/// 매장 순위 데이터 모델
class StoreRanking {
  final String storeName;
  final double avgScore;
  final double avgUserRating;
  final int reviewCount;
  final double avgTrust;
  final int rank;
  final List<String>? topTags;

  StoreRanking({
    required this.storeName,
    required this.avgScore,
    required this.avgUserRating,
    required this.reviewCount,
    required this.avgTrust,
    required this.rank,
    this.topTags,
  });

  factory StoreRanking.fromViewJson(Map<String, dynamic> json, int rankIndex) {
    return StoreRanking(
      storeName: json['store_name']?.toString() ?? '알 수 없음',
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      avgUserRating: (json['avg_user_rating'] as num?)?.toDouble() ?? 0.0,
      avgTrust: (json['avg_trust'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      rank: rankIndex,
    );
  }
}

/// 통계 및 피드백 모델
class Stats {
  final int total;
  final double average;
  final double avgTrust;
  Stats({required this.total, required this.average, required this.avgTrust});
}

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
      id: json['id']?.toString() ?? '',
      userId: json['users']?['user_number']?.toString() ?? 'unknown',
      email: json['email']?.toString(),
      // ✅ 테이블 컬럼명이 'message'가 아닐 경우 방어 처리 유지
      message: json['message']?.toString() ?? json['content']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}