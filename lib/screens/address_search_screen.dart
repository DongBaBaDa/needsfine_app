import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 더미 데이터: [요청 3] 기능 구현을 위해 위도/경도 추가
  final List<Map<String, String>> _savedAddresses = [
    {
      'title': '경북 포항시 북구 두호동 680',
      'subtitle': '경북 포항시 북구 해안로 99-1 호텔 코드 301호',
      'lat': '36.0583',
      'lng': '129.3837',
    },
    {
      'title': '전라남도 순천시 해룡면 장선배기길 176',
      'subtitle': '전라남도 순천시 해룡면 장선배기길 176 바비빌 203호',
      'lat': '34.9429',
      'lng': '127.5252',
    },
  ];

  Future<void> _findAndReturnCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        Navigator.pop(context, LatLng(position.latitude, position.longitude));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("현재 위치를 가져오는 데 실패했습니다.")),
        );
      }
    }
  }

  // [요청 3] 주소 설정 확인 팝업 표시
  void _showSetAddressDialog(Map<String, String> address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("주소 설정"),
        content: const Text("해당 위치로 주소를 설정하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("아니오"),
          ),
          TextButton(
            onPressed: () {
              final location = LatLng(
                double.parse(address['lat']!),
                double.parse(address['lng']!),
              );
              // 이전 팝업 닫고, 지도 화면으로 위치 전달하며 돌아가기
              Navigator.pop(ctx);
              Navigator.pop(context, location); 
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
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
              decoration: const InputDecoration(
                hintText: "도로명, 건물명 또는 지번으로 검색", 
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
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
            onTap: () { /* TODO: [요청 2] 집 주소 저장 기능 구현 필요 */ },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('회사 추가'),
            onTap: () { /* TODO: [요청 2] 회사 주소 저장 기능 구현 필요 */ },
          ),
          Container(height: 8, color: Colors.grey[200]),
          Expanded(
            child: ListView.builder(
              itemCount: _savedAddresses.length,
              itemBuilder: (context, index) {
                final addr = _savedAddresses[index];
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(addr['title']!),
                      subtitle: Text(addr['subtitle']!),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _savedAddresses.removeAt(index);
                          });
                        },
                      ),
                      onTap: () => _showSetAddressDialog(addr), // [요청 3] 팝업 호출
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
