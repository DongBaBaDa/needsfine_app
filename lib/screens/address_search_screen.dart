import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; // NLatLng 사용
import 'package:shared_preferences/shared_preferences.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

// 주소 저장을 위한 데이터 모델
class SavedAddress {
  final String type; // 'HOME', 'WORK', or 'OTHER'
  final String title;
  final String subtitle;
  final double lat;
  final double lng;

  SavedAddress({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'lat': lat,
        'lng': lng,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        type: json['type'],
        title: json['title'],
        subtitle: json['subtitle'],
        lat: json['lat'],
        lng: json['lng'],
      );
}

// 네이버 검색 API 결과 모델
class NaverSearchResult {
  final String roadAddress;
  final String jibunAddress;
  final double x; // 경도 (Longitude)
  final double y; // 위도 (Latitude)

  NaverSearchResult({
    required this.roadAddress,
    required this.jibunAddress,
    required this.x,
    required this.y,
  });

  factory NaverSearchResult.fromJson(Map<String, dynamic> json) {
    return NaverSearchResult(
      roadAddress: json['roadAddress'] ?? '',
      jibunAddress: json['jibunAddress'] ?? '',
      x: double.tryParse(json['x'] ?? '0') ?? 0.0,
      y: double.tryParse(json['y'] ?? '0') ?? 0.0,
    );
  }
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedAddress> _savedAddresses = [];
  List<NaverSearchResult> _searchResults = [];
  bool _isSearching = false;

  // [수정] 새로운 지도 전용 Client ID와 Secret으로 교체
  final String _clientId = '1rst5nv703'; 
  final String _clientSecret = 'FTC0ifJsvXdQQOI91bzqFbIhZ8pZUWAKb3MToqsW'; 

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  // SharedPreferences에서 저장된 주소 목록 불러오기
  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesJson = prefs.getStringList('saved_addresses') ?? [];
    setState(() {
      _savedAddresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  // 현재 주소 목록을 SharedPreferences에 저장하기
  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addressesJson =
        _savedAddresses.map((addr) => jsonEncode(addr.toJson())).toList();
    await prefs.setStringList('saved_addresses', addressesJson);
  }

  // 네이버 Geocoding API 호출
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final url = Uri.parse(
          'https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=$query');
      
      // [수정] Referer 헤더 제거 (Web URL 등록 안했으므로)
      final headers = {
        'X-NCP-APIGW-API-KEY-ID': _clientId.trim(),
        'X-NCP-APIGW-API-KEY': _clientSecret.trim(),
        'Accept': 'application/json',
      };

      print("Requesting: $url");
      final response = await http.get(url, headers: headers);
      print("API Response Code: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['addresses'] != null && (data['addresses'] as List).isNotEmpty) {
          final addresses = data['addresses'] as List;
          setState(() {
            _searchResults = addresses.map((item) {
              return NaverSearchResult.fromJson(item);
            }).toList();
          });
        } else {
           setState(() => _searchResults = []);
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("검색 결과가 없습니다.")),
          );
        }
      } else {
         // 에러 메시지 상세 파싱
         String errorCode = "";
         String errorMsg = "";
         try {
           final errorBody = jsonDecode(response.body);
           if (errorBody is Map && errorBody.containsKey('error')) {
             errorCode = errorBody['error']['errorCode']?.toString() ?? "";
             errorMsg = errorBody['error']['message'] ?? "";
           }
         } catch (_) {}

         if (errorMsg.isEmpty) errorMsg = response.reasonPhrase ?? "Unknown Error";

         print('Geocoding Error: ${response.statusCode} [$errorCode] $errorMsg');
         
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("오류 $errorCode: $errorMsg"),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Search Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("검색 중 오류가 발생했습니다.")),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }


  // '현재 위치로 주소 찾기' 기능
  Future<void> _findAndReturnCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        // NLatLng 반환
        Navigator.pop(context, NLatLng(position.latitude, position.longitude));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("현재 위치를 가져오는 데 실패했습니다.")),
      );
    }
  }
  
  void _onSearchResultTap(NaverSearchResult result) {
      final lat = result.y;
      final lng = result.x;
      
      showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("위치 확인"),
        content: Text("${result.roadAddress}\n이 위치로 이동하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // 닫기
              Navigator.pop(context, NLatLng(lat, lng)); // 결과 반환
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // 저장된 주소 클릭 시 확인 다이얼로그 표시
  void _showSetAddressDialog(SavedAddress address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("주소 설정"),
        content: const Text("해당 위치로 주소를 설정하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("아니오")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, NLatLng(address.lat, address.lng));
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // 집/회사 추가 다이얼로그
  void _showAddAddressDialog(String type) {
    final textController = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(type == 'HOME' ? '집 주소 추가' : '회사 주소 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text("주소를 검색하여 좌표를 저장하는 것이 정확합니다.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                   TextField(
                      controller: textController,
                      decoration: const InputDecoration(hintText: '별칭 입력 (예: 우리집)'), 
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
                TextButton(
                  onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("상단 검색창을 이용해 주소를 검색해주세요.")));
                  },
                  child: const Text("검색하러 가기"),
                ),
              ],
            ));
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('주소 설정', style: TextStyle(color: Colors.black)),
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "도로명, 건물명 또는 지번으로 검색",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send), 
                  onPressed: () => _searchAddress(_searchController.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _searchAddress,
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          
          // 검색 결과 리스트 (결과가 있을 때만 표시)
          if (_searchResults.isNotEmpty)
             Expanded(
               child: ListView.builder(
                 itemCount: _searchResults.length,
                 itemBuilder: (context, index) {
                   final item = _searchResults[index];
                   return Column(
                     children: [
                       ListTile(
                         title: Text(item.roadAddress),
                         subtitle: Text(item.jibunAddress),
                         onTap: () => _onSearchResultTap(item),
                       ),
                       const Divider(height: 1),
                     ],
                   );
                 },
               ),
             )
          else 
             Expanded(
              child: Column(
                children: [
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.my_location),
                    title: const Text('현재 위치로 주소 찾기'),
                    onTap: _findAndReturnCurrentLocation,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('집 추가'),
                    onTap: () => _showAddAddressDialog('HOME'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.work_outline),
                    title: const Text('회사 추가'),
                    onTap: () => _showAddAddressDialog('WORK'),
                  ),
                  Container(height: 8, color: Colors.grey[200]),
                  // 저장된 주소 목록
                  Expanded(
                    child: ListView.builder(
                      itemCount: _savedAddresses.length,
                      itemBuilder: (context, index) {
                        final addr = _savedAddresses[index];
                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(addr.type == 'HOME' 
                                  ? Icons.home 
                                  : addr.type == 'WORK' 
                                      ? Icons.work
                                      : Icons.location_on_outlined),
                              title: Text(addr.title),
                              subtitle: Text(addr.subtitle),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    _savedAddresses.removeAt(index);
                                  });
                                  _saveAddresses();
                                },
                              ),
                              onTap: () => _showSetAddressDialog(addr),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
             ),
        ],
      ),
    );
  }
}
