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

  // ✅ [복구] 누락되었던 이메일 필드
  final String? userEmail;

  // 추가 필드 (댓글 및 날짜)
  final String? myCommentText;
  final DateTime? myCommentCreatedAt;

  // 계산된 속성 (late final)
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

    // ✅ [수정] userEmail 파라미터 복구
    this.userEmail,

    this.myCommentText,
    this.myCommentCreatedAt,

    // 외부 주입 파라미터 (nullable)
    double? needsfineScore,
    int? trustLevel,
    bool? isCritical,
    bool? isHidden,

    // ✅ [추가] 호환용 tags 파라미터 (store_reviews_screen 등에서 tags: 로 넘길 때 컴파일되도록)
    List<String>? tags,

    // 기존 파라미터 유지
    List<String>? dbTags,
  }) {
    // 1. 텍스트 분석 결과 계산
    final scoreData = ScoreCalculator.calculateNeedsFineScore(
        reviewText,
        userRating,
        photoUrls.isNotEmpty
    );

    // 2. 값 할당 (입력값 우선 -> 없으면 계산값)
    final dynamic calcNeedsfine = scoreData['needsfine_score'];
    final dynamic calcTrust = scoreData['trust_level'];
    final dynamic calcCritical = scoreData['is_critical'];

    this.needsfineScore = needsfineScore ??
        ((calcNeedsfine is num) ? calcNeedsfine.toDouble() : 0.0);

    this.trustLevel = trustLevel ??
        ((calcTrust is num) ? calcTrust.toInt() : 0);

    // ✅ [핵심 수정] Null일 수 있는 값을 (as bool)로 캐스팅하지 않도록 방지
    this.isCritical = isCritical ?? (calcCritical == true);

    this.isHidden = isHidden ?? (this.trustLevel < 20);

    // 3. 태그 병합
    final calculatedTags = List<String>.from(scoreData['tags'] ?? []);

    // ✅ dbTags 우선, 없으면 tags(호환용) 사용
    final savedTags = dbTags ?? tags ?? [];

    // DB 태그 우선 + 중복 제거
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
    String? email; // 이메일 추출

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

    // JSON에서 태그 리스트 파싱
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      parsedTags = List<String>.from(json['tags']);
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

      // ✅ 이메일 전달
      userEmail: email,

      storeLat: (json['store_lat'] as num?)?.toDouble() ?? 0.0,
      storeLng: (json['store_lng'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      myCommentText: json['comment_content']?.toString(),
      myCommentCreatedAt: json['comment_created_at'] != null
          ? DateTime.parse(json['comment_created_at'].toString())
          : null,

      // DB 값을 생성자로 전달
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

  // ✅ [수정] 방탄 파싱 로직 적용 (타입 에러 방지)
  factory StoreRanking.fromViewJson(Map<String, dynamic> json, int rank) {
    // 안전한 변환 헬퍼 함수
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
      avgUserRating: toDouble(json['avg_user_rating']), // DB 컬럼명 확인
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
