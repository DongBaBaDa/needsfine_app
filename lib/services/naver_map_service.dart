import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverGeocodingService {
  final String clientId;
  final String clientSecret;

  NaverGeocodingService({required this.clientId, required this.clientSecret});

  // 주소를 검색하여 좌표를 반환하는 메서드
  Future<dynamic> searchAddress(String query) async {
    final url = Uri.https("naveropenapi.apigw.ntruss.com", "/map-geocode/v2/geocode", {"query": query});

    final response = await http.get(url, headers: {
      "X-NCP-APIGW-API-KEY-ID": clientId,
      "X-NCP-APIGW-API-KEY": clientSecret,
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return NaverGeocodingResponse.fromJson(decoded);
    } else {
      throw Exception("주소 검색 실패: ${response.statusCode}");
    }
  }
}

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
  final String x; // 경도
  final String y; // 위도
  final String roadAddress;
  AddrItem({required this.x, required this.y, required this.roadAddress});
  factory AddrItem.fromJson(Map<String, dynamic> json) {
    return AddrItem(x: json['x'], y: json['y'], roadAddress: json['roadAddress']);
  }
}