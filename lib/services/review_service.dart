// lib/services/review_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/ranking_models.dart';

/// NEEDSFINE 리뷰 API 서비스
/// 웹 프로젝트의 index.ts 엔드포인트와 통신합니다.
class ReviewService {
  
  // ==========================================
  // 유저 ID 관리 (웹의 localStorage와 동일)
  // ==========================================
  
  /// 로컬 저장소에서 유저 ID 가져오기
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('needsfine_user_id');
  }

  /// 로컬 저장소에 유저 ID 저장
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('needsfine_user_id', userId);
    print('💾 유저 ID 저장: $userId');
  }

  // ==========================================
  // 리뷰 API
  // ==========================================

  /// 📝 리뷰 작성 (POST /reviews)
  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
  }) async {
    try {
      final userId = await getUserId();

      print('📤 리뷰 작성 요청...');
      print('  가게: $storeName');
      print('  별점: $userRating');
      print('  사진: ${photoUrls?.length ?? 0}장');

      final response = await http.post(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: json.encode({
          'store_name': storeName,
          'store_address': storeAddress,
          'review_text': reviewText,
          'user_rating': userRating,
          'user_id': userId,
          'photo_urls': photoUrls ?? [],
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        // 서버에서 반환한 user_id 저장
        if (data['users'] != null && data['users']['user_number'] != null) {
          await saveUserId(data['users']['user_number']);
        }

        print('✅ 리뷰 작성 성공!');
        return Review.fromJson(data);
      } else {
        print('❌ 리뷰 작성 실패: ${response.statusCode}');
        print('   응답: ${response.body}');
        throw Exception('Failed to create review: ${response.body}');
      }
    } catch (e) {
      print('❌ 리뷰 작성 에러: $e');
      rethrow;
    }
  }

  /// 📋 리뷰 목록 조회 (GET /reviews)
  static Future<List<Review>> fetchReviews({
    int limit = 20,
    String? storeName,
  }) async {
    try {
      String url = '${SupabaseConfig.apiBaseUrl}/reviews?limit=$limit';
      if (storeName != null && storeName.isNotEmpty) {
        url += '&store_name=${Uri.encodeComponent(storeName)}';
      }

      print('📥 리뷰 목록 요청: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        final reviews = data
            .where((r) => r != null && r['needsfine_score'] != null)
            .map((r) => Review.fromJson(r))
            .toList();

        print('✅ 리뷰 ${reviews.length}개 로드 완료');
        return reviews;
      } else if (response.statusCode == 404) {
        print('⚠️ 서버가 배포되지 않았습니다.');
        return [];
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 리뷰 목록 로드 실패: $e');
      return [];
    }
  }

  /// 🔍 특정 리뷰 조회 (GET /reviews/:id)
  static Future<Review?> fetchReviewById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/reviews/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return Review.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load review');
      }
    } catch (e) {
      print('❌ 리뷰 조회 실패: $e');
      return null;
    }
  }

  /// 📊 통계 조회 (GET /stats)
  static Future<Map<String, dynamic>?> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      print('❌ 통계 조회 실패: $e');
      return null;
    }
  }

  // ==========================================
  // 피드백 API
  // ==========================================

  /// 💬 피드백 작성 (POST /feedback)
  static Future<Feedback> createFeedback({
    String? email,
    required String message,
  }) async {
    try {
      final userId = await getUserId();

      final response = await http.post(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: json.encode({
          'email': email,
          'message': message,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        // 서버에서 반환한 user_id 저장
        if (data['users'] != null && data['users']['user_number'] != null) {
          await saveUserId(data['users']['user_number']);
        }

        print('✅ 피드백 전송 성공!');
        return Feedback.fromJson(data);
      } else {
        throw Exception('Failed to create feedback: ${response.body}');
      }
    } catch (e) {
      print('❌ 피드백 전송 실패: $e');
      rethrow;
    }
  }

  /// 📋 피드백 목록 조회 (GET /feedback)
  static Future<List<Feedback>> fetchFeedbacks({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/feedback?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data
            .where((f) => f != null)
            .map((f) => Feedback.fromJson(f))
            .toList();
      } else if (response.statusCode == 404) {
        print('⚠️ 서버가 배포되지 않았습니다.');
        return [];
      } else {
        throw Exception('Failed to load feedbacks');
      }
    } catch (e) {
      print('❌ 피드백 목록 로드 실패: $e');
      return [];
    }
  }

  // ==========================================
  // 관리자 API
  // ==========================================

  /// 🔐 관리자 인증 확인
  static Future<bool> verifyAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/admin/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953", // [수정] 직접 문자열 사용
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ 관리자 인증 실패: $e');
      return false;
    }
  }

  /// 🗑️ 관리자 - 리뷰 삭제
  static Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/admin/reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953", // [수정] 직접 문자열 사용
        },
      );

      if (response.statusCode == 200) {
        print('🗑️ 리뷰 삭제 성공: $reviewId');
        return true;
      } else {
        print('❌ 리뷰 삭제 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 리뷰 삭제 에러: $e');
      return false;
    }
  }

  /// 🗑️ 관리자 - 피드백 삭제
  static Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/admin/feedback/$feedbackId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953", // [수정] 직접 문자열 사용
        },
      );

      if (response.statusCode == 200) {
        print('🗑️ 피드백 삭제 성공: $feedbackId');
        return true;
      } else {
        print('❌ 피드백 삭제 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 피드백 삭제 에러: $e');
      return false;
    }
  }

  /// 🔄 관리자 - 모든 리뷰 재계산
  static Future<Map<String, dynamic>?> recalculateAllReviews() async {
    try {
      print('🔄 모든 리뷰 재계산 시작...');
      
      final response = await http.post(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/recalculate-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953", // [수정] 직접 문자열 사용
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 재계산 완료: ${result['success_count']}개 성공, ${result['error_count']}개 실패');
        return result;
      } else {
        print('❌ 재계산 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 재계산 에러: $e');
      return null;
    }
  }

  // ==========================================
  // 👍👎 커뮤니티 검증 (투표)
  // ==========================================

  /// 👍 리뷰 추천/비추천
  static Future<Map<String, dynamic>?> voteReview({
    required String reviewId,
    required String voteType, // 'like' or 'dislike'
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('User ID not found. Please write a review first.');
      }

      final response = await http.post(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/reviews/$reviewId/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: json.encode({
          'user_id': userId,
          'vote_type': voteType,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        print('✅ 투표 성공: $voteType');
        return result;
      } else if (response.statusCode == 409) {
        print('⚠️ 이미 투표한 리뷰입니다.');
        return {'error': 'Already voted'};
      } else {
        throw Exception('Failed to vote: ${response.body}');
      }
    } catch (e) {
      print('❌ 투표 실패: $e');
      return null;
    }
  }
}
