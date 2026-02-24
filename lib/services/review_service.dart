import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/config/supabase_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:needsfine_app/services/genius_feedback_service.dart';
import 'package:flutter/foundation.dart';


class ReviewService {
  static final _supabase = Supabase.instance.client;
  static const String _baseUrl = 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/make-server-26899706';

  // --- 조회 (Fetch) ---

  // ✅ [수정됨] 통계 조회 (에러 로그 추가)
  static Future<Map<String, dynamic>> fetchGlobalStats() async {
    try {
      final response = await _supabase.rpc('get_global_review_stats');
      return response as Map<String, dynamic>;
    } catch (e) {
      print("❌ fetchGlobalStats 에러: $e");
      return {'total_reviews': 0, 'average_score': 0.0, 'avg_trust': 0.0};
    }
  }

  // ✅ [핵심 수정] 매장 랭킹 조회 (디버깅 로그 대폭 추가)
  // 이 함수가 실행될 때 콘솔(Run탭)을 확인해주세요!
  static Future<List<StoreRanking>> fetchStoreRankings() async {
    try {
      print("🚀 [Debug] get_store_rankings RPC 호출 시작...");

      // 1. RPC 호출
      final response = await _supabase.rpc('get_store_rankings');

      print("🔥 [Debug] DB 응답 원본: $response");

      if (response == null) {
        print("❌ [Debug] DB 응답이 NULL입니다.");
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        print("⚠️ [Debug] DB에서 빈 리스트([])가 반환되었습니다. (데이터가 없거나 is_hidden=true)");
        return [];
      }

      // 🗺️ 첫 항목의 키 목록과 좌표 데이터 확인
      if (data.isNotEmpty) {
        final first = data.first as Map<String, dynamic>;
        print("🗺️ [Debug] RPC 반환 키 목록: ${first.keys.toList()}");
        print("🗺️ [Debug] store_lat: ${first['store_lat']}, store_lng: ${first['store_lng']}, store_address: ${first['store_address']}");
      }

      // 2. 데이터 매핑 (여기서 에러가 터질 확률 99%)
      return data.asMap().entries.map((entry) {
        try {
          return StoreRanking.fromViewJson(entry.value, entry.key + 1);
        } catch (e, stack) {
          print("💥 [CRITICAL] 데이터 파싱 에러 발생!");
          print("   - 순위: ${entry.key + 1}위");
          print("   - 원인: $e");
          print("   - 문제의 데이터: ${entry.value}");
          // 에러가 나도 죽지 않고 리스트를 반환하기 위해 예외를 던지지 않고 무시하거나 처리해야 함
          // 여기서는 원인 파악을 위해 rethrow 함
          rethrow;
        }
      }).toList();

    } catch (e) {
      print("💀 [FATAL] fetchStoreRankings 전체 에러: $e");
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
      print("❌ fetchReviews 에러: $e");
      return [];
    }
  }

  // --- 생성 (Create) ---
  // ✅ tags 파라미터 추가됨
  static Future<Review> createReview({
    required String storeName,
    String? storeAddress,
    required String reviewText,
    required double userRating,
    List<String>? photoUrls,
    double? lat,
    double? lng,
    List<String>? tags, // ✅ 태그 파라미터 추가
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
          'tags': tags ?? [], // ✅ JSON 본문에 태그 포함
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Review.fromJson(data);
      } else {
        throw Exception('리뷰 등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ createReview 에러: $e");
      rethrow;
    }
  }

  // --- 수정 (Update) ---
  // ✅ 리뷰 수정 시 서버 분석 재호출 후 점수 반영
  static Future<void> updateReview({
    required String reviewId,
    required String content,
    required double rating,
    required List<String> photoUrls,
    List<String>? tags,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다.');

      // ✅ 서버에 재분석 요청 (점수/신뢰도 재계산)
      final Map<String, dynamic> updateData = {
        'review_text': content,
        'user_rating': rating,
        'photo_urls': photoUrls,
        'tags': tags ?? [],
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        final analysis = await analyzeReview(
          text: content,
          userRating: rating,
          hasPhoto: photoUrls.isNotEmpty,
          tags: tags ?? [],
        );
        // 분석 성공 시 점수도 함께 업데이트
        if (analysis['needsfine_score'] != null && analysis['needsfine_score'] != 0.0) {
          updateData['needsfine_score'] = analysis['needsfine_score'];
          updateData['trust_level'] = analysis['trust_level'];
        }
      } catch (e) {
        debugPrint('⚠️ 분석 재호출 실패 (점수 유지): $e');
        // 분석 실패해도 텍스트/사진 등은 업데이트 진행
      }

      await _supabase.from('reviews').update(updateData)
          .eq('id', reviewId).eq('user_id', userId);

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

  // 조회수 증가
  static Future<void> incrementViewCount(String reviewId) async {
    try {
      // ✅ [Fix] Use dedicated RPC for review view count
      await _supabase.rpc('increment_review_view_count', params: {
        'row_id': reviewId
      });
    } catch (e) {
      debugPrint("❌ 조회수 증가 실패: $e");
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



  // ✅ [New] 실시간 리뷰 분석 (Server Only)
  static Future<Map<String, dynamic>> analyzeReview({
    required String text,
    required double userRating,
    required bool hasPhoto,
    required List<String> tags, // ✅ 태그 파라미터 추가
  }) async {
    try {
      // 1. 서버 시도 (Edge Function, 10초 타임아웃)
      final response = await _supabase.functions.invoke(
        'make-server-26899706/analyze',
        body: {
          'reviewText': text,
          'userRating': userRating,
          'hasPhoto': hasPhoto,
          'tags': tags, // ✅ 배달/포장 태그 전달 (서버 피드백 우선순위용)
        },
      ).timeout(const Duration(milliseconds: 10000));

      final data = response.data;
      if (data == null) throw Exception("분석 결과 없음");

      // ✅ [Fix] Genius Feedback 적용 (태그 전달)
      final genius = GeniusFeedbackService.generateFeedback(text, userRating, tags);

      return {
        'needsfine_score': (data['needsfine_score'] as num?)?.toDouble() ?? 0.0,
        'trust_level': (data['trust_level'] as num?)?.toInt() ?? 0,
        'message': genius.message, // Genius 메시지 사용
        'is_warning': data['is_warning'] ?? false,
      };

    } catch (e) {
      print("❌ 서버 분석 실패: $e");
      
      // 에러 시에도 Genius Feedback은 작동하도록 (오프라인/에러 대응)
      final genius = GeniusFeedbackService.generateFeedback(text, userRating, tags);

      return {
        'needsfine_score': 0.0,
        'trust_level': 0,
        'message': genius.message, // "서버 에러" 대신 분석 메시지라도 보여줌
        'is_warning': true,
      };
    }
  }

  static Future<String?> getUserId() async {
    return _supabase.auth.currentUser?.id;
  }
}