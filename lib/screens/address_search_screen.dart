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
  final String title;
  final String address;
  final String roadAddress;
  final double mapx;
  final double mapy;

  NaverSearchResult({
    required this.title,
    required this.address,
    required this.roadAddress,
    required this.mapx,
    required this.mapy,
  });

  factory NaverSearchResult.fromJson(Map<String, dynamic> json) {
    // mapx, mapy는 카텍 좌표계로 올 수 있으므로 주의 필요 (API 문서 확인 중요)
    // 네이버 검색 API (지역)의 mapx, mapy는 정수형 문자열일 수 있음
    return NaverSearchResult(
      title: (json['title'] as String).replaceAll('<b>', '').replaceAll('</b>', ''),
      address: json['address'] ?? '',
      roadAddress: json['roadAddress'] ?? '',
      // 네이버 지역 검색 API의 mapx, mapy는 12841399와 같은 형태로, 1/10,000,000 위경도 값이 아님. 
      // KATECH 좌표계 등으로 제공될 수 있어, Geocoding API를 별도로 호출하거나 좌표 변환이 필요할 수 있음.
      // 여기서는 Geocoding API를 사용한다고 가정하고 구조만 잡거나,
      // 간단한 테스트를 위해 네이버 지도 API Geocoding을 호출하는 로직을 별도로 구현해야 함.
      // *중요*: 네이버 검색 API는 좌표를 바로 쓸 수 있는 위경도(LatLng)로 주지 않는 경우가 많음.
      // 따라서 네이버 클라우드 플랫폼의 "Geocoding" API를 직접 호출하는 것이 가장 정확함.
      mapx: 0.0, 
      mapy: 0.0,
    );
  }
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedAddress> _savedAddresses = [];
  List<NaverSearchResult> _searchResults = [];
  bool _isSearching = false;

  // 네이버 클라우드 플랫폼 Client ID & Secret
  final String _clientId = 'peiu5pezpj'; 
  final String _clientSecret = '3scnYomd8nIOfDG3Ds8B5STJbJgmDbV3YaMrY3uv'; 

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
      
      final response = await http.get(url, headers: {
        'X-NCP-APIGW-API-KEY-ID': _clientId,
        'X-NCP-APIGW-API-KEY': _clientSecret,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addresses = data['addresses'] as List;
        
        setState(() {
          _searchResults = addresses.map((item) {
            return NaverSearchResult(
              title: item['roadAddress'] ?? item['jibunAddress'],
              address: item['jibunAddress'] ?? '',
              roadAddress: item['roadAddress'] ?? '',
              // API는 문자열로 좌표를 줌
              mapx: double.parse(item['x']), // 경도 (Longitude)
              mapy: double.parse(item['y']), // 위도 (Latitude)
            );
          }).toList();
        });
      } else {
         print('Geocoding Error: ${response.statusCode} ${response.body}');
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("주소 검색 실패: ${response.statusCode}")),
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
      // 검색 결과를 선택했을 때 다이얼로그 혹은 바로 이동
      // 좌표계: Geocoding API 결과는 위도(y), 경도(x)
      final lat = result.mapy;
      final lng = result.mapx;
      
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

  // 집/회사 추가 다이얼로그 (단순 텍스트 입력 대신 검색 유도 가능하나, 여기서는 유지)
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
                      // 실제로는 검색 로직을 타야 하지만, 임시로 현재 위치 저장 로직 등으로 대체 가능
                      // 여기서는 생략
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
                   return ListTile(
                     title: Text(item.roadAddress),
                     subtitle: Text(item.address), // 지번 주소
                     onTap: () => _onSearchResultTap(item),
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
