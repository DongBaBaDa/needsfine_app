import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/config/supabase_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  static final _supabase = Supabase.instance.client;
  static const String _baseUrl = 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/make-server-26899706';

  static Future<Map<String, dynamic>> fetchGlobalStats() async {
    try {
      final response = await _supabase
          .from('global_stats_view')
          .select()
          .single();
      return response;
    } catch (e) {
      print('❌ 전체 통계 로드 실패: $e');
      return {};
    }
  }

  static Future<List<StoreRanking>> fetchStoreRankings() async {
    try {
      final List<dynamic> response = await _supabase
          .from('store_rankings_view')
          .select()
          .order('avg_score', ascending: false)
          .limit(100);

      return response.asMap().entries.map((entry) {
        return StoreRanking.fromViewJson(entry.value, entry.key + 1);
      }).toList();
    } catch (e) {
      print('❌ 매장 순위 로드 실패: $e');
      return [];
    }
  }

  static Future<List<Review>> fetchReviews({
    int limit = 20,
    int offset = 0,
    String? storeName,
  }) async {
    try {
      // ✅ [Fix] profiles 테이블에서 profile_image_url까지 가져오도록 명시
      var query = _supabase
          .from('reviews')
          .select('*, profiles(nickname, user_number, email, profile_image_url)')
          .eq('is_hidden', false);

      if (storeName != null && storeName.isNotEmpty) {
        query = query.ilike('store_name', '%$storeName%');
      }

      final List<dynamic> data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('❌ 리뷰 목록 로드 실패: $e');
      return [];
    }
  }

  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      final String? accessToken = session?.accessToken;
      final String? userId = _supabase.auth.currentUser?.id;

      final String authHeader = accessToken != null
          ? 'Bearer $accessToken'
          : 'Bearer ${SupabaseConfig.anonKey}';

      final url = Uri.parse('$_baseUrl/reviews');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode({
          'store_name': storeName,
          'store_address': storeAddress,
          'review_text': reviewText,
          'user_rating': userRating,
          'photo_urls': photoUrls ?? [],
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          throw Exception('서버 응답이 비어있습니다.');
        }
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Review.fromJson(data);
      } else {
        throw Exception('리뷰 등록 실패 (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ 리뷰 작성 에러: $e');
      rethrow;
    }
  }

  static Future<String?> getUserId() async {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }

  static Future<bool> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
      return true;
    } catch (e) {
      return false;
    }
  }
}