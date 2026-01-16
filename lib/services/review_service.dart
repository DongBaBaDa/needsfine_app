import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/ranking_models.dart';

/// NEEDSFINE 리뷰 API 서비스
class ReviewService {

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
    print('💾 유저 ID 저장: $userId');
  }

  // ==========================================
  // 리뷰 API
  // ==========================================

  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
  }) async {
    try {
      final userId = await getUserId();
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
        if (data['users'] != null && data['users']['user_number'] != null) {
          await saveUserId(data['users']['user_number']);
        }
        return Review.fromJson(data);
      } else {
        throw Exception('Failed to create review: ${response.body}');
      }
    } catch (e) {
      print('❌ 리뷰 작성 에러: $e');
      rethrow;
    }
  }

  /// 📋 리뷰 목록 조회 (GET /reviews)
  /// [수정] offset 파라미터 추가 (무한 스크롤용)
  static Future<List<Review>> fetchReviews({
    int limit = 20,
    int offset = 0, // ✅ 추가됨: 건너뛸 개수
    String? storeName,
  }) async {
    try {
      // ✅ URL에 offset 파라미터 추가
      String url = '${SupabaseConfig.apiBaseUrl}/reviews?limit=$limit&offset=$offset';
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

        print('✅ 리뷰 ${reviews.length}개 로드 완료 (Offset: $offset)');
        return reviews;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 리뷰 목록 로드 실패: $e');
      return [];
    }
  }

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
  // 피드백 및 기타 API (기존 유지)
  // ==========================================

  static Future<Feedback> createFeedback({String? email, required String message}) async {
    try {
      final userId = await getUserId();
      final response = await http.post(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: json.encode({'email': email, 'message': message, 'user_id': userId}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['users'] != null && data['users']['user_number'] != null) {
          await saveUserId(data['users']['user_number']);
        }
        return Feedback.fromJson(data);
      } else {
        throw Exception('Failed to create feedback: ${response.body}');
      }
    } catch (e) {
      print('❌ 피드백 전송 실패: $e');
      rethrow;
    }
  }

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
        return data.where((f) => f != null).map((f) => Feedback.fromJson(f)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load feedbacks');
      }
    } catch (e) {
      print('❌ 피드백 목록 로드 실패: $e');
      return [];
    }
  }

  static Future<bool> verifyAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/admin/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953",
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/admin/reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953",
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/admin/feedback/$feedbackId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953",
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> recalculateAllReviews() async {
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/recalculate-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'X-Admin-Password': "needsfine2953",
        },
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> voteReview({required String reviewId, required String voteType}) async {
    try {
      final userId = await getUserId();
      if (userId == null) throw Exception('User ID not found');

      final response = await http.post(
        Uri.parse('${SupabaseConfig.apiBaseUrl}/reviews/$reviewId/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: json.encode({'user_id': userId, 'vote_type': voteType}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 409) {
        return {'error': 'Already voted'};
      } else {
        throw Exception('Failed to vote: ${response.body}');
      }
    } catch (e) {
      return null;
    }
  }
}