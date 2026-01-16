import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ranking_models.dart';

/// NEEDSFINE 리뷰 API 서비스 (Supabase v2 문법 + 에러 수정 완료)
class ReviewService {
  static final _supabase = Supabase.instance.client;

  // ==========================================
  // 유저 ID 관리
  // ==========================================

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('needsfine_user_id');
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('needsfine_user_id', userId);
  }

  // ==========================================
  // 리뷰 API
  // ==========================================

  /// 📝 리뷰 작성
  /// ✅ [수정] DB 필수 컬럼(점수 등) 누락으로 인한 에러 해결
  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
  }) async {
    try {
      final userId = await getUserId();

      final response = await _supabase.from('reviews').insert({
        'store_name': storeName,
        'store_address': storeAddress,
        'review_text': reviewText,
        'user_rating': userRating,
        'photo_urls': photoUrls ?? [],
        'user_id': userId,

        // 🔹 [핵심] DB의 NOT NULL 제약조건을 피하기 위한 기본값 설정
        // (실제 분석 로직이 연결되기 전까지는 기본값으로 저장되어야 에러가 안 납니다)
        'needsfine_score': 70.0,
        'trust_level': 50,
        'authenticity': true,
        'advertising_words': false,
        'emotional_balance': true,
        'is_critical': false,
        'tags': [],

      }).select().single();

      return Review.fromJson(response);
    } catch (e) {
      print('❌ 리뷰 작성 에러: $e');
      rethrow;
    }
  }

  /// 📋 리뷰 목록 조회 (무한 스크롤)
  static Future<List<Review>> fetchReviews({
    int limit = 20,
    int offset = 0,
    String? storeName,
  }) async {
    try {
      var query = _supabase.from('reviews').select();

      if (storeName != null && storeName.isNotEmpty) {
        query = query.ilike('store_name', '%$storeName%');
      }

      // ✅ 최신순 정렬 + 범위 지정 (offset ~ offset + limit)
      final List<dynamic> data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('❌ 리뷰 목록 로드 실패: $e');
      return [];
    }
  }

  /// 🔍 특정 리뷰 조회
  static Future<Review?> fetchReviewById(String id) async {
    try {
      final response = await _supabase.from('reviews').select().eq('id', id).single();
      return Review.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 📊 통계 조회
  /// ✅ [수정] 단순 개수 카운트가 아니라 '실제 평균 점수'를 계산하도록 변경
  static Future<Map<String, dynamic>?> fetchStats() async {
    try {
      // 1. 점수와 신뢰도 컬럼만 가져옴 (전체 데이터)
      final List<dynamic> scores = await _supabase
          .from('reviews')
          .select('needsfine_score, trust_level');

      if (scores.isEmpty) {
        return {
          'total_reviews': 0,
          'average_score': 0.0,
          'average_trust': 0.0,
        };
      }

      // 2. 앱 내에서 평균 계산
      double totalScore = 0;
      double totalTrust = 0;

      for (var item in scores) {
        totalScore += (item['needsfine_score'] as num).toDouble();
        totalTrust += (item['trust_level'] as num).toDouble();
      }

      return {
        'total_reviews': scores.length,
        'average_score': totalScore / scores.length, // 실제 평균
        'average_trust': totalTrust / scores.length, // 실제 평균
      };
    } catch (e) {
      print('❌ 통계 조회 실패: $e');
      return {'total_reviews': 0};
    }
  }

  /// 🗑️ 리뷰 삭제
  static Future<bool> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 기타 기능
  // ==========================================

  static Future<Map<String, dynamic>?> voteReview({
    required String reviewId,
    required String voteType,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) throw Exception('로그인이 필요합니다.');

      final response = await _supabase.from('review_votes').insert({
        'user_id': userId,
        'review_id': reviewId,
        'vote_type': voteType,
      }).select().single();

      return response;
    } catch (e) {
      return {'error': 'Already voted or failed'};
    }
  }

  static Future<void> createFeedback({String? email, required String message}) async {
    final userId = await getUserId();
    await _supabase.from('feedback').insert({
      'email': email,
      'message': message,
      'user_id': userId,
    });
  }

  static Future<List<Feedback>> fetchFeedbacks({int limit = 20}) async {
    try {
      final data = await _supabase.from('feedback').select().limit(limit);
      return (data as List).map((json) => Feedback.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> verifyAdmin() async {
    return true;
  }
}