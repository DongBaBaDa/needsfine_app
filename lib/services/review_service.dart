import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/config/supabase_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  static final _supabase = Supabase.instance.client;
  static const String _baseUrl = 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/make-server-26899706';

  // --- 조회 (Fetch) ---
  static Future<Map<String, dynamic>> fetchGlobalStats() async {
    try {
      final response = await _supabase.from('global_stats_view').select().single();
      return response;
    } catch (e) {
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
      return [];
    }
  }

  static Future<List<Review>> fetchReviews({int limit = 20, int offset = 0, String? storeName}) async {
    try {
      var query = _supabase
          .from('reviews')
          .select('*, profiles(nickname, user_number, email, profile_image_url)')
          .eq('is_hidden', false);

      if (storeName != null && storeName.isNotEmpty) {
        query = query.ilike('store_name', '%$storeName%');
      }

      final List<dynamic> data = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- 생성 (Create) ---
  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
    double? lat,
    double? lng,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      final String? accessToken = session?.accessToken;
      final String? userId = _supabase.auth.currentUser?.id;

      final String authHeader = accessToken != null ? 'Bearer $accessToken' : 'Bearer ${SupabaseConfig.anonKey}';
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
          'store_lat': lat,
          'store_lng': lng,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Review.fromJson(data);
      } else {
        throw Exception('리뷰 등록 실패');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- 수정 (Update) ---
  static Future<void> updateReview({
    required String reviewId,
    required String content,
    required double rating,
    required List<String> photoUrls,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다.');

      // ✅ RLS 정책이 있더라도 명시적으로 user_id 체크
      await _supabase.from('reviews').update({
        'review_text': content,
        'user_rating': rating,
        'photo_urls': photoUrls,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId).eq('user_id', userId); // 내 글인지 확인

    } catch (e) {
      print('❌ 리뷰 수정 실패: $e');
      rethrow;
    }
  }

  // --- 삭제 (Delete) ---
  static Future<bool> deleteReview(String reviewId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId); // 내 글인지 확인

      return true;
    } catch (e) {
      print('❌ 리뷰 삭제 실패: $e');
      return false;
    }
  }

  // --- 좋아요 (Toggle Like) ---
  static Future<bool> toggleLike(String reviewId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다.');

      // 1. 이미 좋아요를 눌렀는지 확인
      final existing = await _supabase
          .from('review_votes')
          .select()
          .eq('review_id', reviewId)
          .eq('user_id', userId)
          .eq('vote_type', 'like')
          .maybeSingle();

      if (existing != null) {
        // [CASE 1] 이미 있음 -> 취소 (삭제)
        await _supabase.from('review_votes').delete().eq('id', existing['id']);

        // ✅ SQL 함수 호출 (decrement)
        try {
          await _supabase.rpc('decrement_like_count', params: {'row_id': reviewId});
        } catch (rpcError) {
          print("RPC Error (decrement): $rpcError");
          // RPC가 실패해도 vote는 지워졌으므로 진행
        }
        return false; // 꺼짐

      } else {
        // [CASE 2] 없음 -> 추가
        await _supabase.from('review_votes').insert({
          'review_id': reviewId,
          'user_id': userId,
          'vote_type': 'like',
        });

        // ✅ SQL 함수 호출 (increment)
        try {
          await _supabase.rpc('increment_like_count', params: {'row_id': reviewId});
        } catch (rpcError) {
          print("RPC Error (increment): $rpcError");
        }
        return true; // 켜짐
      }
    } catch (e) {
      print('❌ 좋아요 처리 에러: $e');
      rethrow;
    }
  }

  static Future<String?> getUserId() async {
    return _supabase.auth.currentUser?.id;
  }
}