// lib/models/ranking_models.dart
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

  // ✅ 좌표 필드
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

// ✅ [수정 완료] StoreRanking 클래스 복구
// ReviewService에서 호출하는 `fromViewJson` 메서드를 정확히 구현함
class StoreRanking {
  final String storeName;
  final double avgScore;
  final double avgUserRating;
  final int reviewCount;
  final double avgTrust;
  final int rank;

  // ✅ UI에서 에러가 안 나도록 nullable이 아닌 빈 리스트로 초기화
  final List<String> topTags;

  // ✅ RankingScreen에서 사용하는 변수명 'address'
  final String? address;

  // ✅ 지도 이동을 위한 좌표
  final double? lat;
  final double? lng;

  StoreRanking({
    required this.storeName,
    required this.avgScore,
    required this.avgUserRating,
    required this.reviewCount,
    required this.avgTrust,
    required this.rank,
    required this.topTags,
    this.address,
    this.lat,
    this.lng,
  });

  // 🚨 [핵심 수정] ReviewService가 호출하는 메서드명으로 복구 & rankIndex 파라미터 부활
  factory StoreRanking.fromViewJson(Map<String, dynamic> json, int rankIndex) {
    return StoreRanking(
      storeName: json['store_name']?.toString() ?? '알 수 없음',
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      avgUserRating: (json['avg_user_rating'] as num?)?.toDouble() ?? 0.0,
      avgTrust: (json['avg_trust'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,

      // ✅ 서비스에서 계산해서 넘겨준 순위(rankIndex) 사용
      rank: rankIndex,

      // ✅ tags가 null이면 빈 리스트([]) 반환하여 View 에러 방지
      topTags: (json['top_tags'] as List?)?.map((e) => e.toString()).toList() ?? [],

      // ✅ DB의 'store_address' 컬럼을 View의 'address' 변수에 매핑
      address: json['store_address']?.toString(),

      // ✅ 좌표 파싱
      lat: (json['store_lat'] as num?)?.toDouble(),
      lng: (json['store_lng'] as num?)?.toDouble(),
    );
  }
}

class Stats {
  final int total;
  final double average;
  final double avgTrust;

  Stats({
    required this.total,
    required this.average,
    required this.avgTrust
  });
}