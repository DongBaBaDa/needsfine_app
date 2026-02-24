// 파일 이름: lib/models/ranking_models.dart
// import 'package:needsfine_app/services/score_calculator.dart'; // Removed

class Review {
  final String id;
  final String storeName;
  final String? storeAddress;
  final String reviewText;
  final double userRating;
  final List<String> photoUrls;
  final String userId;
  final String nickname;
  final String? userProfileUrl;
  final double storeLat;
  final double storeLng;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  // ✅ [추가] 저장(스크랩) 수 및 조회수 필드 추가
  final int saveCount;
  final int viewCount;
  
  // ✅ [추가] 방명록(N번째 방문) 횟수 추가
  final int visitCount;
  
  // ✅ [추가] 거리 필드 (계산 후 주입)
  final double? distance;

  final String? userEmail;
  final String? myCommentText;
  final DateTime? myCommentCreatedAt;

  late final double needsfineScore;
  late final int trustLevel;
  late final bool isCritical;
  late final bool isHidden;
  late final List<String> tags;

  Review({
    required this.id,
    required this.storeName,
    this.storeAddress,
    required this.reviewText,
    required this.userRating,
    required this.photoUrls,
    required this.userId,
    required this.nickname,
    this.userProfileUrl,
    required this.storeLat,
    required this.storeLng,
    required this.createdAt,
    required this.likeCount,
    this.commentCount = 0,
    this.saveCount = 0,
    this.viewCount = 0, // ✅ 기본값
    this.visitCount = 1, // ✅ 기본 방문 횟수
    this.distance,      // ✅ 초기화
    this.userEmail,
    this.myCommentText,
    this.myCommentCreatedAt,
    double? needsfineScore,
    int? trustLevel,
    bool? isCritical,
    bool? isHidden,
    List<String>? tags,
    List<String>? dbTags,
  }) {
    // ✅ [수정] ScoreCalculator 제거. 서버에서 계산된 값(needsfineScore 등)을 그대로 사용하거나 기본값 0 처리
    this.needsfineScore = needsfineScore ?? 0.0;
    this.trustLevel = trustLevel ?? 0;
    this.isCritical = isCritical ?? false;
    this.isHidden = isHidden ?? false;

    // 태그 병합 로직 간소화 (DB태그 우선)
    this.tags = dbTags ?? tags ?? [];
  }

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
    String? email;

    if (profileData != null) {
      if (profileData['nickname'] != null) {
        displayNickname = profileData['nickname'].toString();
      }
      if (profileData['profile_image_url'] != null) {
        profileUrl = profileData['profile_image_url'].toString();
      }
      if (profileData['email'] != null) {
        email = profileData['email'].toString();
      }
    } else {
      displayNickname = _generateDeterministicNickname(uid ?? json['id'].toString());
    }

    List<String> parsedTags = [];
    if (json['tags'] != null) {
      parsedTags = List<String>.from(json['tags']);
    }

    // ✅ [핵심] Supabase Relation Count 파싱 헬퍼 함수
    int parseCount(dynamic data) {
      if (data is int) return data; // 만약 물리적인 컬럼이라면
      if (data is List && data.isNotEmpty) {
        // Relation Count인 경우: [{count: 3}] 형태
        return (data[0]['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    }

    return Review(
      id: json['id']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '이름 없음',
      storeAddress: json['store_address']?.toString(),
      reviewText: json['review_text']?.toString() ?? '',
      userRating: (json['user_rating'] as num?)?.toDouble() ?? 0.0,
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      userId: uid ?? '',
      nickname: displayNickname,
      userProfileUrl: profileUrl,
      userEmail: email,
      storeLat: (json['store_lat'] as num?)?.toDouble() ?? 0.0,
      storeLng: (json['store_lng'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),

      // ✅ [수정] 물리적 컬럼(like_count) 우선 확인 후, 없으면 Relation Count 파싱
      likeCount: (json['like_count'] as int?) ?? parseCount(json['review_votes']),
      commentCount: (json['comment_count'] as int?) ?? parseCount(json['comments']),
      saveCount: (json['save_count'] as int?) ?? parseCount(json['review_saves']),
      viewCount: (json['view_count'] as int?) ?? 0, // ✅ 조회수 파싱
      visitCount: (json['visit_count'] as int?) ?? 1, // ✅ N번째 리뷰
      distance: (json['distance'] as num?)?.toDouble(), // ✅ 거리 파싱 (있으면)

      myCommentText: json['comment_content']?.toString(),
      myCommentCreatedAt: json['comment_created_at'] != null
          ? DateTime.parse(json['comment_created_at'].toString())
          : null,

      needsfineScore: (json['needsfine_score'] as num?)?.toDouble(),
      trustLevel: (json['trust_level'] as num?)?.toInt(),
      isCritical: json['is_critical'] == true,
      isHidden: json['is_hidden'] == true,
      dbTags: parsedTags,
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
  final List<String> topTags;
  final String? address;
  final double? lat;
  final double? lng;
  final double? distance; // ✅ 거리 필드 추가
  final String? imageUrl; // ✅ [Added] 매장 이미지(리뷰 사진 등)

  StoreRanking({
    required this.storeName,
    required this.avgScore,
    required this.avgUserRating,
    required this.reviewCount,
    required this.avgTrust,
    required this.rank,
    this.topTags = const [],
    this.address,
    this.lat,
    this.lng,
    this.distance,
    this.imageUrl,
  });

  factory StoreRanking.fromViewJson(Map<String, dynamic> json, int rank) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return 0;
    }

    return StoreRanking(
      storeName: json['store_name']?.toString() ?? '',
      avgScore: toDouble(json['avg_score']),
      avgUserRating: toDouble(json['avg_user_rating']),
      reviewCount: toInt(json['review_count']),
      avgTrust: toDouble(json['avg_trust']),
      rank: rank,
      topTags: (json['top_tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      address: json['store_address']?.toString(),
      lat: toDouble(json['store_lat']),
      lng: toDouble(json['store_lng']),
      distance: (json['distance'] as num?)?.toDouble(), // ✅ 거리 파싱
    );
  }
}

class Stats {
  final int total;
  final double average;
  final double avgTrust;

  Stats({required this.total, required this.average, required this.avgTrust});
}