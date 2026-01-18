import 'dart:convert';
import 'package:http/http.dart' as http;

// -----------------------------------------------------------------------------
// Model: 네이버 검색 결과 (장소)
// -----------------------------------------------------------------------------
class NaverPlace {
  final String title;       // 업체명 (HTML 태그 포함)
  final String category;    // 카테고리
  final String address;     // 지번 주소
  final String roadAddress; // 도로명 주소

  NaverPlace({
    required this.title,
    required this.category,
    required this.address,
    required this.roadAddress,
  });

  factory NaverPlace.fromJson(Map<String, dynamic> json) {
    return NaverPlace(
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      roadAddress: json['roadAddress'] ?? '',
    );
  }

  // HTML 태그(<b> 등)를 제거하고 순수 텍스트만 반환하는 Getter
  String get cleanTitle {
    return title
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML 태그 제거
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
  }
}

// -----------------------------------------------------------------------------
// Service: 네이버 지역 검색 API (Local Search)
// -----------------------------------------------------------------------------
class NaverSearchService {
  // ✅ 발급받은 네이버 개발자 센터(Open API) 키 적용
  static const String clientId = 'nSB4KhHoTg3bvXWCIRNP';
  static const String clientSecret = '2dxOLY0voJ';

  // 네이버 지역 검색 API 엔드포인트
  static const String baseUrl = 'https://openapi.naver.com/v1/search/local.json';

  Future<List<NaverPlace>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      print("🔍 [Naver Search] 검색 요청: $query"); // 디버깅용 로그

      final response = await http.get(
        Uri.parse('$baseUrl?query=$query&display=5&start=1&sort=random'),
        headers: {
          'X-Naver-Client-Id': clientId,
          'X-Naver-Client-Secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];

        print("✅ [Naver Search] 검색 성공: ${items.length}개 발견"); // 디버깅용 로그

        return items.map((item) => NaverPlace.fromJson(item)).toList();
      } else {
        print('🛑 [Naver Search Error] 상태 코드: ${response.statusCode}');
        print('에러 내용: ${response.body}');
        return [];
      }
    } catch (e) {
      print('🛑 [Naver Search Exception] 오류 발생: $e');
      return [];
    }
  }
}