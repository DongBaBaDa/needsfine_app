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
  final String? userProfileUrl;
  final int commentCount;

  // ✅ [기존 유지] 좌표 필드
  final double? storeLat;
  final double? storeLng;

  final String? myCommentText;
  final DateTime? myCommentCreatedAt;

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
    this.userProfileUrl,
    this.commentCount = 0,
    this.storeLat,
    this.storeLng,
    this.myCommentText,
    this.myCommentCreatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'];

    String? uid;
    if (profileData != null && profileData['id'] != null) {
      uid = profileData['id'].toString();
    } else {
      uid = json['user_id']?.toString();
    }

    String displayNickname = '익명 사용자';
    String? profileUrl;

    if (profileData != null) {
      if (profileData['nickname'] != null) {
        displayNickname = profileData['nickname'].toString();
      }
      if (profileData['profile_image_url'] != null) {
        profileUrl = profileData['profile_image_url'].toString();
      }
    } else {
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
      userProfileUrl: profileUrl,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      storeLat: (json['store_lat'] as num?)?.toDouble(),
      storeLng: (json['store_lng'] as num?)?.toDouble(),
      myCommentText: json['comment_content']?.toString(),
      myCommentCreatedAt: json['comment_created_at'] != null
          ? DateTime.parse(json['comment_created_at'].toString())
          : null,
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

// ✅ [수정됨] StoreRanking 클래스에 좌표 및 주소 필드 추가
class StoreRanking {
  final String storeName;
  final double avgScore;
  final double avgUserRating;
  final int reviewCount;
  final double avgTrust;
  final int rank;
  final List<String>? topTags;

  // 추가된 필드
  final double? storeLat;
  final double? storeLng;
  final String? storeAddress;

  StoreRanking({
    required this.storeName,
    required this.avgScore,
    required this.avgUserRating,
    required this.reviewCount,
    required this.avgTrust,
    required this.rank,
    this.topTags,
    this.storeLat,      // 추가
    this.storeLng,      // 추가
    this.storeAddress,  // 추가
  });

  factory StoreRanking.fromViewJson(Map<String, dynamic> json, int rankIndex) {
    return StoreRanking(
      storeName: json['store_name']?.toString() ?? '알 수 없음',
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      avgUserRating: (json['avg_user_rating'] as num?)?.toDouble() ?? 0.0,
      avgTrust: (json['avg_trust'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      rank: rankIndex,
      // ✅ JSON에서 좌표/주소 파싱 (DB 컬럼명이 store_lat, store_lng, store_address 라고 가정)
      storeLat: (json['store_lat'] as num?)?.toDouble(),
      storeLng: (json['store_lng'] as num?)?.toDouble(),
      storeAddress: json['store_address']?.toString(),
    );
  }
}

class Stats {
  final int total;
  final double average;
  final double avgTrust;
  Stats({required this.total, required this.average, required this.avgTrust});
}