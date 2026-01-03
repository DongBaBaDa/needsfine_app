import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/ranking_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Completer<NaverMapController> _controller = Completer();
  final _addressController = TextEditingController();
  StreamSubscription<Position>? _positionStreamSubscription;

  Store? _selectedStore;

  // 초기 위치: 서울시청
  static const NCameraPosition _initialPosition = NCameraPosition(
    target: NLatLng(37.5665, 126.9780),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
    searchTrigger.addListener(_handleExternalSearch);
  }

  void _handleExternalSearch() {
    if (searchTrigger.value != null && searchTrigger.value!.isNotEmpty) {
      _searchAndMove(searchTrigger.value!);
      searchTrigger.value = null;
    }
  }

  @override
  void dispose() {
    searchTrigger.removeListener(_handleExternalSearch);
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
    var status = await Permission.location.status;
    if (status.isDenied) status = await Permission.location.request();

    if (status.isGranted) {
      final position = await Geolocator.getCurrentPosition();
      final nLatLng = NLatLng(position.latitude, position.longitude);
      _updateLocationAndMarkers(nLatLng, moveCamera: true);
    }
  }

  // 주소 검색 및 카메라 이동
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
      }
    } catch (e) {
      debugPrint("검색 실패: $e");
    }
  }

  // 마커 업데이트 로직
  Future<void> _updateMarkers(NaverMapController controller) async {
    final markers = <NMarker>{};

    for (var store in AppData().stores) {
      // 위젯을 이미지로 변환하여 마커 아이콘으로 사용
      final iconImage = await NOverlayImage.fromWidget(
          widget: _buildMarkerWidget(store),
          context: context
      );

      final marker = NMarker(
        id: store.id,
        position: NLatLng(store.latitude, store.longitude),
        icon: iconImage,
        size: const Size(110, 45), // 마커 크기 최적화
      );

      marker.setOnTapListener((overlay) {
        setState(() => _selectedStore = store);
      });

      markers.add(marker);
    }

    controller.clearOverlays();
    controller.addOverlayAll(markers);
  }

  Widget _buildMarkerWidget(Store store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kNeedsFinePurple, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2))]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("💎", style: TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            store.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLocationAndMarkers(NLatLng location, {bool moveCamera = false, String? addressText}) async {
    if (moveCamera) {
      final controller = await _controller.future;
      controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: location, zoom: 15));
    }
    if (addressText != null) {
      setState(() => _addressController.text = addressText);
    }
    final controller = await _controller.future;
    _updateMarkers(controller);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('내 주변')),
      body: Column(
        children: [
          // 상단 주소 검색바
          _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                NaverMap(
                  options: const NaverMapViewOptions(
                    initialCameraPosition: _initialPosition,
                    locationButtonEnable: true,
                    indoorEnable: true,
                  ),
                  onMapReady: (controller) {
                    if (!_controller.isCompleted) _controller.complete(controller);
                    _updateMarkers(controller);
                  },
                  onMapTapped: (_, __) => setState(() => _selectedStore = null),
                ),
                // 선택된 상점 정보 카드
                if (_selectedStore != null)
                  Positioned(
                    bottom: 20, left: 16, right: 16,
                    child: _buildStoreInfoSheet(_selectedStore!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: _addressController,
        decoration: InputDecoration(
          hintText: '지번, 도로명 주소로 검색',
          prefixIcon: const Icon(Icons.location_on, color: kNeedsFinePurple),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchAndMove(_addressController.text),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        onFieldSubmitted: _searchAndMove,
      ),
    );
  }

  Widget _buildStoreInfoSheet(Store store) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network('https://via.placeholder.com/60', width: 60, height: 60, fit: BoxFit.cover),
        ),
        title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("⭐ ${store.userRating.toStringAsFixed(1)} | 니즈파인 인증"),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _selectedStore = null),
        ),
      ),
    );
  }
}