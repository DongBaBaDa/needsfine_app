import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/ranking_screen.dart'; // [수정] 파일명 언더바 확인

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with AutomaticKeepAliveClientMixin {
  // 탭 이동 시 상태를 유지하기 위해 true 설정
  @override
  bool get wantKeepAlive => true;

  final Completer<NaverMapController> _controller = Completer();
  final _addressController = TextEditingController();
  StreamSubscription<Position>? _positionStreamSubscription;

  Store? _selectedStore;

  static const NCameraPosition _initialPosition = NCameraPosition(
    target: NLatLng(37.5665, 126.9780),
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
    // [추가] 외부(리뷰 화면)에서 보낸 주소를 처리하기 위한 리스너
    searchTrigger.addListener(_handleExternalSearch);
  }

  // 외부 트리거 감지 시 실행
  void _handleExternalSearch() {
    if (searchTrigger.value != null && searchTrigger.value!.isNotEmpty) {
      final address = searchTrigger.value!;
      _searchAndMove(address);
      searchTrigger.value = null; // 처리 후 초기화하여 무한 루프 방지
    }
  }

  @override
  void dispose() {
    searchTrigger.removeListener(_handleExternalSearch); // 리스너 해제 필수
    _positionStreamSubscription?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    final prefs = await SharedPreferences.getInstance();
    final userAddress = prefs.getString('user_address');
    if (userAddress != null && userAddress.isNotEmpty) {
      await _searchAndMove(userAddress);
    } else {
      _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      final position = await Geolocator.getCurrentPosition();
      final nLatLng = NLatLng(position.latitude, position.longitude);
      _updateLocationAndMarkers(nLatLng, moveCamera: true);
    }
  }

  // Geocoding API를 이용한 검색 및 이동
  Future<void> _searchAndMove(String address) async {
    final geocodingService = NaverGeocodingService(
      clientId: '1rst5nv703',
      clientSecret: 'FTC0ifJsvXdQQOI91bzqFbIhZ8pZUWAKb3MToqsW',
    );
    try {
      final response = await geocodingService.searchAddress(address);
      if (response.addresses.isNotEmpty) {
        final addr = response.addresses.first;
        final position = NLatLng(double.parse(addr.y), double.parse(addr.x));
        _updateLocationAndMarkers(position, moveCamera: true, addressText: address);
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('주소를 찾을 수 없습니다.')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('주소 검색 실패: $e')));
    }
  }

  Future<void> _updateMarkers(NaverMapController controller, NLatLng center) async {
    final newMarkers = <NMarker>{};
    for (var store in AppData().stores) {
      final iconImage = await NOverlayImage.fromWidget(widget: _buildMarkerWidget(store), context: context);
      final marker = NMarker(
          id: store.id,
          position: NLatLng(store.latitude, store.longitude),
          icon: iconImage,
          size: const Size(120, 50),
          anchor: const NPoint(0.5, 0.5)
      );
      marker.setOnTapListener((overlay) {
        setState(() => _selectedStore = store);
        return true;
      });
      newMarkers.add(marker);
    }
    controller.clearOverlays();
    controller.addOverlayAll(newMarkers);
  }

  Widget _buildMarkerWidget(Store store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF9C7CFF), width: 2)
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(radius: 10, child: Text("🇰🇷", style: TextStyle(fontSize: 12))),
        const SizedBox(width: 4),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(store.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
          const Text("니즈파인 인증", style: TextStyle(fontSize: 9, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Future<void> _moveCamera(NLatLng position) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    final cameraUpdate = NCameraUpdate.scrollAndZoomTo(target: position, zoom: 15.0)
      ..setAnimation(animation: NCameraAnimation.easing);
    await controller.updateCamera(cameraUpdate);
  }

  Future<void> _updateLocationAndMarkers(NLatLng location, {bool moveCamera = false, String? addressText}) async {
    if (!mounted) return;
    if (moveCamera) await _moveCamera(location);
    final controller = await _controller.future;
    await _updateMarkers(controller, location);
    if (addressText != null) {
      if(mounted) setState(() => _addressController.text = addressText);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필수
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 주변', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: '지번, 도로명 주소로 검색',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF9C7CFF)),
                  onPressed: () => _searchAndMove(_addressController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onFieldSubmitted: (value) => _searchAndMove(value),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                NaverMap(
                  options: const NaverMapViewOptions(
                      initialCameraPosition: _initialPosition,
                      locationButtonEnable: true,
                      logoClickEnable: false
                  ),
                  onMapReady: (controller) {
                    if (!_controller.isCompleted) _controller.complete(controller);
                  },
                  onMapTapped: (point, latLng) => setState(() => _selectedStore = null),
                ),
                if (_selectedStore != null)
                  Positioned(bottom: 20, left: 20, right: 20, child: _buildStoreInfoSheet(_selectedStore!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoSheet(Store store) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network('https://via.placeholder.com/150', width: 80, height: 80, fit: BoxFit.cover)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(" ${store.userRating.toStringAsFixed(1)}")]),
            ]),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedStore = null))
        ]),
      ),
    );
  }
}