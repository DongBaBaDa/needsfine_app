import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/config/supabase_config.dart'; // AnonKey 사용을 위해 필요하다면 추가
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  static final _supabase = Supabase.instance.client;

  // Edge Function URL
  static const String _functionUrl = 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/make-server-26899706';

  // ==========================================
  // 1. 전체 통계 가져오기
  // ==========================================
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

  // ==========================================
  // 2. 매장 순위 가져오기
  // ==========================================
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

  // ==========================================
  // 3. 리뷰 목록 가져오기
  // ==========================================
  static Future<List<Review>> fetchReviews({
    int limit = 20,
    int offset = 0,
    String? storeName,
  }) async {
    try {
      var query = _supabase.from('reviews').select().eq('is_hidden', false);

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

  // ==========================================
  // 4. 리뷰 작성 (401 오류 수정됨)
  // ==========================================
  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
  }) async {
    try {
      // ✅ [Fix] 현재 로그인한 사용자의 세션 토큰 가져오기
      final session = _supabase.auth.currentSession;
      final String? accessToken = session?.accessToken;

      // 토큰이 없으면 Anon Key라도 보내야 Edge Function이 401을 뱉지 않음 (Function 설정에 따라 다름)
      // 여기서는 유저 토큰을 우선으로 하고, 없으면 AnonKey를 보냄
      final String authHeader = accessToken != null
          ? 'Bearer $accessToken'
          : 'Bearer ${SupabaseConfig.anonKey}';

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader, // 👈 401 해결을 위한 핵심 코드
        },
        body: jsonEncode({
          'store_name': storeName,
          'store_address': storeAddress,
          'review_text': reviewText,
          'user_rating': userRating,
          'photo_urls': photoUrls ?? [],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 응답 본문이 비어있을 수 있으므로 체크
        if (response.body.isEmpty) {
          throw Exception('서버 응답이 비어있습니다.');
        }
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Review.fromJson(data);
      } else {
        throw Exception('리뷰 등록 실패: ${response.body}');
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