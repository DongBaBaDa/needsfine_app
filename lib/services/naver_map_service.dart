import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverGeocodingService {
  // ✅ 새로 발급받은 키 적용 완료
  final String clientId = 'xqcofdggzk';
  final String clientSecret = 'wRkaosDLeSLLJfSAS4vwAIyLpnB8aWLupZptAMH4';

  NaverGeocodingService();

  Future<NaverGeocodingResponse> searchAddress(String query) async {
    // 1. [수정 완료] 도메인을 'maps.apigw.ntruss.com'으로 변경!
    // Uri.https를 사용하면 쿼리 인코딩도 자동으로 안전하게 처리됩니다.
    final url = Uri.https(
        "maps.apigw.ntruss.com",
        "/map-geocode/v2/geocode",
        {"query": query.trim()}
    );

    print("🚀 [API 요청 시작] ------------------------------------------------");
    print("👉 요청 URL: $url");
    print("👉 전송 ID: '$clientId'");

    final response = await http.get(
      url,
      headers: {
        "X-NCP-APIGW-API-KEY-ID": clientId.trim(),
        "X-NCP-APIGW-API-KEY": clientSecret.trim(),
        "Accept": "application/json"
      },
    );

    // 2. 응답 처리
    if (response.statusCode == 200) {
      print("✅ [성공] 주소 검색 완료");
      final decoded = json.decode(response.body);
      return NaverGeocodingResponse.fromJson(decoded);
    } else {
      // 3. 에러 발생 시 상세 분석
      print("🛑 [API 오류] =============================");
      print("Status Code: ${response.statusCode}");

      String errorBody = "";
      try {
        errorBody = utf8.decode(response.bodyBytes);
      } catch (e) {
        errorBody = response.body;
      }
      print("Error Body: $errorBody");
      print("==========================================");

      throw Exception("주소 검색 실패: ${response.statusCode} / $errorBody");
    }
  }
}

// 모델 클래스 (그대로 유지)
class NaverGeocodingResponse {
  final List<AddrItem> addresses;
  NaverGeocodingResponse({required this.addresses});

  factory NaverGeocodingResponse.fromJson(Map<String, dynamic> json) {
    return NaverGeocodingResponse(
      addresses: (json['addresses'] as List? ?? [])
          .map((i) => AddrItem.fromJson(i))
          .toList(),
    );
  }
}

class AddrItem {
  final String x;
  final String y;
  final String roadAddress;

  AddrItem({required this.x, required this.y, required this.roadAddress});

  factory AddrItem.fromJson(Map<String, dynamic> json) {
    return AddrItem(
        x: json['x'] ?? '0.0',
        y: json['y'] ?? '0.0',
        roadAddress: json['roadAddress'] ?? '주소 없음'
    );
  }
}