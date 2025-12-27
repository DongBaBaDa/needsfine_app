// lib/services/review_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:needsfine_app/models/ranking_models.dart';

class ReviewService {
  // 실제 프로젝트 ID와 Anon Key는 환경 변수나 보안 저장소에서 관리하는 것이 좋지만,
  // 요청하신 대로 코드에 직접 포함합니다.
  static const String supabaseProjectId = "YOUR_PROJECT_ID"; 
  static const String supabaseAnonKey = "YOUR_ANON_KEY";     
  static const String apiBaseUrl = "https://$supabaseProjectId.supabase.co/functions/v1/make-server-26899706";

  static Future<List<Review>> fetchReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .where((r) => r != null && r['needsfine_score'] != null)
            .map((r) => Review.fromJson(r))
            .toList();
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      print('❌ 리뷰 로드 실패: $e');
      return [];
    }
  }
}
