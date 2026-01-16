import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; // 리뷰 작성 때만 잠깐 필요할 수 있음

class ReviewService {
  static final _supabase = Supabase.instance.client;

  // ✅ 1. 이 주소는 '리뷰 작성(POST)'할 때만 씁니다. (평균 점수 불러올 땐 안 씀)
  // 재준님이 알려준 Invocation URL 주소를 여기에 넣으세요.
  static const String _functionUrl = 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/make-server-26899706';

  // ==========================================
  // 1. 전체 통계 가져오기 (방금 만든 global_stats_view 사용)
  // ==========================================
  static Future<Map<String, dynamic>> fetchGlobalStats() async {
    try {
      // HTTP 통신 X -> Supabase DB 직접 조회 O
      final response = await _supabase
          .from('global_stats_view')
          .select()
          .single(); // 데이터가 1줄이니까 single()

      // 뷰에서 계산된 값을 그대로 리턴
      return response;
    } catch (e) {
      print('❌ 전체 통계 로드 실패: $e');
      return {};
    }
  }

  // ==========================================
  // 2. 매장 순위 가져오기 (방금 만든 store_rankings_view 사용)
  // ==========================================
  static Future<List<StoreRanking>> fetchStoreRankings() async {
    try {
      final List<dynamic> response = await _supabase
          .from('store_rankings_view')
          .select()
          .order('avg_score', ascending: false) // 점수 높은 순
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
  // 3. 리뷰 목록 가져오기 (기존 테이블 사용)
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
  // 4. 리뷰 작성 (Edge Function 호출)
  // ==========================================
  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
  }) async {
    try {
      // 여기서는 Edge Function을 호출해서 점수를 계산시킴
      final response = await http.post(
        Uri.parse('$_functionUrl'), // 위에서 설정한 진짜 주소
        headers: {
          'Content-Type': 'application/json',
          // 필요한 경우 인증 헤더 추가: 'Authorization': 'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
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

  // 유저 ID 헬퍼 등등...
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('needsfine_user_id');
  }

  static Future<bool> deleteReview(String reviewId) async {
    try { await _supabase.from('reviews').delete().eq('id', reviewId); return true; } catch (e) { return false; }
  }
}