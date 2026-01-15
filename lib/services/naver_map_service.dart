import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverGeocodingService {
  // ✅ Client ID (기존 유지)
  final String clientId = 'uno05gvwyq';

  // ✅ [수정 완료] 재발급받은 새로운 Client Secret 적용
  final String clientSecret = 'fVtIRfmRTmMPtDtiqq6KC873qKjHSX7qNQqSnmVx';

  // 생성자
  NaverGeocodingService();

  // 주소를 검색하여 좌표를 반환하는 메서드
  Future<dynamic> searchAddress(String query) async {
    // 쿼리 파라미터 인코딩 처리 (한글 주소 깨짐 방지)
    final url = Uri.https("naveropenapi.apigw.ntruss.com", "/map-geocode/v2/geocode", {"query": query});

    final response = await http.get(url, headers: {
      // .trim()을 추가하여 혹시 모를 공백 제거 (안전장치)
      "X-NCP-APIGW-API-KEY-ID": clientId.trim(),
      "X-NCP-APIGW-API-KEY": clientSecret.trim(),
      "Accept": "application/json"
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return NaverGeocodingResponse.fromJson(decoded);
    } else {
      // 에러 로그 출력
      print("🛑 [Naver Geocoding Error] =============================");
      print("요청 URL: $url");
      print("Status Code: ${response.statusCode}");

      String errorBody = "";
      try {
        errorBody = utf8.decode(response.bodyBytes);
      } catch (e) {
        errorBody = response.body;
      }
      print("Error Body (원인): $errorBody");
      print("========================================================");

      throw Exception("주소 검색 실패: ${response.statusCode} / $errorBody");
    }
  }
}

// 모델 클래스
class NaverGeocodingResponse {
  final List<AddrItem> addresses;
  NaverGeocodingResponse({required this.addresses});
  factory NaverGeocodingResponse.fromJson(Map<String, dynamic> json) {
    return NaverGeocodingResponse(
      addresses: (json['addresses'] as List).map((i) => AddrItem.fromJson(i)).toList(),
    );
  }
}

class AddrItem {
  final String x;
  final String y;
  final String roadAddress;
  AddrItem({required this.x, required this.y, required this.roadAddress});
  factory AddrItem.fromJson(Map<String, dynamic> json) {
    return AddrItem(x: json['x'], y: json['y'], roadAddress: json['roadAddress']);
  }
}