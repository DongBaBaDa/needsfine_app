// 파일 이름: lib/models/ranking_models.dart
import 'package:needsfine_app/services/score_calculator.dart';

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

  // ✅ [추가] 저장(스크랩) 수 필드 추가
  final int saveCount;

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
    this.saveCount = 0, // ✅ 기본값
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
    final scoreData = ScoreCalculator.calculateNeedsFineScore(
        reviewText,
        userRating,
        photoUrls.isNotEmpty
    );

    final dynamic calcNeedsfine = scoreData['needsfine_score'];
    final dynamic calcTrust = scoreData['trust_level'];
    final dynamic calcCritical = scoreData['is_critical'];

    this.needsfineScore = needsfineScore ??
        ((calcNeedsfine is num) ? calcNeedsfine.toDouble() : 0.0);

    this.trustLevel = trustLevel ??
        ((calcTrust is num) ? calcTrust.toInt() : 0);

    this.isCritical = isCritical ?? (calcCritical == true);
    this.isHidden = isHidden ?? (this.trustLevel < 20);

    final calculatedTags = List<String>.from(scoreData['tags'] ?? []);
    final savedTags = dbTags ?? tags ?? [];
    this.tags = {...savedTags, ...calculatedTags}.toList();
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

      // ✅ [수정] Relation Count 파싱 적용
      likeCount: parseCount(json['review_votes']),
      commentCount: parseCount(json['comments']),
      saveCount: parseCount(json['review_saves']),

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
    );
  }
}

class Stats {
  final int total;
  final double average;
  final double avgTrust;

  Stats({required this.total, required this.average, required this.avgTrust});
}