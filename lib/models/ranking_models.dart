import 'package:intl/intl.dart';

class Review {
  final String id;
  final String storeName;
  final String? storeAddress;
  final String reviewText;
  final double userRating;
  final double needsfineScore;
  final int trustLevel;
  final List<String> tags;
  final List<String> photoUrls;
  final bool isCritical;
  final bool isHidden;
  final DateTime createdAt;
  final String? userId;
  final String? userEmail;
  final int likeCount;
  final String nickname;

  Review({
    required this.id,
    required this.storeName,
    this.storeAddress,
    required this.reviewText,
    required this.userRating,
    required this.needsfineScore,
    required this.trustLevel,
    required this.tags,
    required this.photoUrls,
    required this.isCritical,
    required this.isHidden,
    required this.createdAt,
    this.userId,
    this.userEmail,
    this.likeCount = 0,
    required this.nickname,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // ✅ 수정: 'users' -> 'profiles'로 변경 (DB 테이블명 일치)
    final profileData = json['profiles'];

    String? uid;
    if (profileData != null && profileData['id'] != null) {
      uid = profileData['id'].toString();
    } else {
      uid = json['user_id']?.toString();
    }

    String displayNickname = '익명 사용자';

    // 1. profiles 테이블에 닉네임이 있는지 확인
    if (profileData != null && profileData['nickname'] != null) {
      displayNickname = profileData['nickname'].toString();
    }
    // 2. 없다면 ID 기반으로 결정적 닉네임 생성
    else {
      displayNickname = _generateDeterministicNickname(uid ?? json['id'].toString());
    }

    return Review(
      id: json['id']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      storeAddress: json['store_address']?.toString(),
      reviewText: json['review_text']?.toString() ?? '',
      userRating: (json['user_rating'] as num?)?.toDouble() ?? 3.0,
      needsfineScore: (json['needsfine_score'] as num?)?.toDouble() ?? 70.0,
      trustLevel: (json['trust_level'] as num?)?.toInt() ?? 50,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      photoUrls: (json['photo_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isCritical: json['is_critical'] == true,
      isHidden: json['is_hidden'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      userId: uid,
      userEmail: profileData != null ? profileData['email']?.toString() : null,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      nickname: displayNickname,
    );
  }

  static String _generateDeterministicNickname(String seed) {
    final adjectives = ['행복한', '조용한', '배고픈', '미식가', '성실한', '낭만적인', '바쁜', '매운맛'];
    final animals = ['호랑이', '고양이', '쿼카', '미식가', '탐험가', '부엉이', '거북이', '다람쥐'];

    int hash = seed.hashCode;
    String adj = adjectives[hash.abs() % adjectives.length];
    String animal = animals[(hash.abs() ~/ 10) % animals.length];

    return "$adj $animal";
  }
}

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

class Stats {
  final int total;
  final double average;
  final double avgTrust;
  Stats({required this.total, required this.average, required this.avgTrust});
}