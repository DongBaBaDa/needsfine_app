import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/services/naver_search_service.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Completer<NaverMapController> _controller = Completer();
  final _searchController = TextEditingController();
  StreamSubscription<Position>? _positionStreamSubscription;

  late final NaverGeocodingService _geocodingService;
  late final NaverSearchService _searchService;

  NaverPlace? _searchedPlace;
  Store? _matchedStore;
  bool _showBottomSheet = false;

  static const NCameraPosition _initialPosition = NCameraPosition(
    target: NLatLng(37.5665, 126.9780),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _geocodingService = NaverGeocodingService();
    _searchService = NaverSearchService();
    _initializeMap();
    searchTrigger.addListener(_handleExternalSearch);
  }

  void _handleExternalSearch() {
    if (searchTrigger.value != null && searchTrigger.value!.isNotEmpty) {
      _searchController.text = searchTrigger.value!;
      _handleSearchStep1(searchTrigger.value!);
      searchTrigger.value = null;
    }
  }

  @override
  void dispose() {
    searchTrigger.removeListener(_handleExternalSearch);
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    final prefs = await SharedPreferences.getInstance();
    final userAddress = prefs.getString('user_address');
    if (userAddress != null && userAddress.isNotEmpty) {
      _handleSearchStep1(userAddress, isAddressOnly: true);
    } else {
      _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) status = await Permission.location.request();

    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition();
        final nLatLng = NLatLng(position.latitude, position.longitude);

        final controller = await _controller.future;
        controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: nLatLng, zoom: 15));
      } catch (e) {
        debugPrint("위치 정보 가져오기 실패: $e");
      }
    }
  }

  Future<void> _handleSearchStep1(String query, {bool isAddressOnly = false}) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();

    if (isAddressOnly) {
      _moveMapToAddress(query);
      return;
    }

    final places = await _searchService.searchPlaces(query);

    if (places.isEmpty) {
      _moveMapToAddress(query);
    } else if (places.length == 1) {
      _selectPlace(places.first);
    } else {
      if (!mounted) return;
      _showPlaceSelectionSheet(places);
    }
  }

  Future<void> _moveMapToAddress(String address) async {
    try {
      final response = await _geocodingService.searchAddress(address);
      if (response.addresses.isNotEmpty) {
        final addr = response.addresses.first;
        final position = NLatLng(double.parse(addr.y), double.parse(addr.x));

        final controller = await _controller.future;
        controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: position, zoom: 16));
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
    }
  }

  // ✅ [Design] 커스텀 마커 위젯 (디자인된 핀)
  Widget _buildCustomMarkerWidget(String title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
            ],
            border: Border.all(color: const Color(0xFF9C7CFF), width: 2), // 니즈파인 컬러
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 로고 대신 핀 아이콘 사용 (깔끔하게)
              const Icon(Icons.place, color: Color(0xFF9C7CFF), size: 18),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
        // 말풍선 꼬리
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 12,
            height: 8,
            color: const Color(0xFF9C7CFF),
          ),
        ),
      ],
    );
  }

  Future<void> _selectPlace(NaverPlace place) async {
    try {
      final queryAddr = place.roadAddress.isNotEmpty ? place.roadAddress : place.address;
      final response = await _geocodingService.searchAddress(queryAddr);

      if (response.addresses.isNotEmpty) {
        final addr = response.addresses.first;
        final position = NLatLng(double.parse(addr.y), double.parse(addr.x));

        Store? matched;
        try {
          matched = AppData().stores.firstWhere(
                (s) => s.name.contains(place.cleanTitle) || place.cleanTitle.contains(s.name),
          );
        } catch (_) {
          matched = null;
        }

        setState(() {
          _searchedPlace = place;
          _matchedStore = matched;
          _showBottomSheet = true;
          _searchController.text = place.cleanTitle;
        });

        final controller = await _controller.future;
        controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: position, zoom: 16));

        // ✅ [구현] 커스텀 위젯을 이미지로 변환하여 마커 생성
        final iconImage = await NOverlayImage.fromWidget(
          widget: _buildCustomMarkerWidget(place.cleanTitle),
          context: context,
        );

        final marker = NMarker(
          id: 'search_result',
          position: position,
          icon: iconImage,
          // 캡션은 위젯 안에 넣었으므로 제거하거나 유지
        );

        controller.clearOverlays();
        controller.addOverlay(marker);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("위치 좌표를 찾을 수 없습니다.")));
      }
    } catch (e) {
      debugPrint("Place Selection Error: $e");
    }
  }

  void _showPlaceSelectionSheet(List<NaverPlace> places) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: places.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final place = places[index];
            return ListTile(
              title: Text(place.cleanTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(place.roadAddress),
              onTap: () {
                Navigator.pop(context);
                _selectPlace(place);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: _initialPosition,
              locationButtonEnable: true,
              indoorEnable: true,
            ),
            onMapReady: (controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            onMapTapped: (_, __) {
              if (_showBottomSheet) {
                setState(() => _showBottomSheet = false);
              }
            },
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '맛집 검색 (예: 강남역 파스타)',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF9C7CFF)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (val) => _handleSearchStep1(val),
                  ),
                ),
              ),
            ),
          ),

          if (_showBottomSheet && _searchedPlace != null)
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.15,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40, height: 4,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        _buildSheetContent(),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSheetContent() {
    final place = _searchedPlace!;
    final store = _matchedStore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.cleanTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            place.category.replaceAll('>', ' > '),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          if (store != null) ...[
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  store.userRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  "(${store.reviewCount}개의 리뷰)",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text("📋 니즈파인 AI 분석 요약", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0E9FF), borderRadius: BorderRadius.circular(12)),
              child: Text(
                store.summary ?? "아직 요약된 정보가 없습니다.",
                style: const TextStyle(color: Color(0xFF6200EE)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    "아직 등록된 정보가 없습니다.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "'당신의 경험을 공유해주세요!'",
                    style: TextStyle(fontSize: 14, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                // ✅ [수정] 리뷰 작성 화면으로 "선택된 장소" 정보도 함께 넘길 수 있도록 설계
                // WriteReviewScreen 내부에서 _selectedPlace 정보를 활용하도록 변경됨
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WriteReviewScreen()),
                );
                if (result == true) {
                  setState(() => _showBottomSheet = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("소중한 리뷰 감사합니다!")));
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text("첫 번째 리뷰 작성하기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C7CFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  place.roadAddress.isNotEmpty ? place.roadAddress : place.address,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// 핀 꼬리 모양 클리퍼
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}