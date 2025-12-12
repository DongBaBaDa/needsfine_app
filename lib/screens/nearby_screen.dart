import 'dart:async';
import 'dart:math'; // For random store locations

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart'; // 1. 'flutter pub add geocoding' 실행 후 주석을 해제하세요.
import 'package:permission_handler/permission_handler.dart';

import 'package:needsfine_app/models/app_data.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {}; // 변경: final이 아닌 Set으로 변경
  LatLng? _currentMapCenter;

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFirstLocationUpdate = true;
  bool _showRecenterButton = false;
  String _displayLocation = '위치 확인 중...';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780), // Default to Seoul
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      _startListeningToLocation();
    } else {
      _handleLocationError('위치 권한이 거부되어 지도 기능을 사용할 수 없습니다.');
    }
  }

  void _startListeningToLocation() {
    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);
        if (_isFirstLocationUpdate && mounted) {
          _isFirstLocationUpdate = false;
          _moveCameraToCurrentLocation(newPosition);
          _updateLocationAndMarkers(newPosition); // 초기 위치로 업데이트
        }
      },
      onError: (error) => _handleLocationError('현재 위치를 추적하는 데 실패했습니다.'),
    );
  }

  // [신규] 지도 중심을 기준으로 주변에 가상 가게 마커 Set을 생성하여 반환합니다. (setState 없음)
  Set<Marker> _generateMarkers(LatLng center) {
    final newMarkers = <Marker>{};
    final random = Random();
    for (var store in AppData().stores) {
      // 반경 약 1km 내에 랜덤으로 가게 위치를 생성합니다. (더미 데이터용)
      final storePosition = LatLng(
        center.latitude + (random.nextDouble() - 0.5) * 0.01,
        center.longitude + (random.nextDouble() - 0.5) * 0.01,
      );
      newMarkers.add(
        Marker(
          markerId: MarkerId(store.id),
          position: storePosition,
          infoWindow: InfoWindow(title: store.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }
    return newMarkers;
  }

  Future<void> _moveCameraToCurrentLocation(LatLng position) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: 16.0)));
  }

  // [수정] 위치 정보(주소), 마커, UI 상태를 한 번에 업데이트하는 통합 함수
  Future<void> _updateLocationAndMarkers(LatLng location) async {
    if (!mounted) return;

    String newDisplayLocation;
    // --- 주소 변환 로직 (geocoding 패키지 필요) ---
    // 2. 아래의 try-catch 블록 주석을 해제하면 실제 주소로 변환됩니다.
    /*
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        newDisplayLocation = "${p.street}"; // 예: "테헤란로 152"
      } else {
        newDisplayLocation = '주소를 찾을 수 없음';
      }
    } catch (e) {
      print("주소 변환 오류: $e");
      newDisplayLocation = '주소 변환 실패';
    }
    */
    
    // 주소 변환 기능 구현 전까지는 좌표로 표시합니다.
    newDisplayLocation = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

    // 새로운 마커 Set을 생성합니다.
    final newMarkers = _generateMarkers(location);

    // setState를 한 번만 호출하여 모든 UI 상태를 업데이트합니다.
    setState(() {
      _currentMapCenter = location;
      _displayLocation = newDisplayLocation;
      _markers = newMarkers; // 마커 교체
      _showRecenterButton = false; // 버튼 숨김
    });
  }

  void _handleLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _displayLocation = '위치를 찾을 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/address-search'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Flexible(child: Text(_displayLocation, style: const TextStyle(fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            markers: _markers,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            compassEnabled: true,
            onCameraMoveStarted: () {
              if (mounted) setState(() => _showRecenterButton = true);
            },
            onCameraMove: (position) => _currentMapCenter = position.target,
          ),
          const IgnorePointer(child: Icon(Icons.location_pin, color: Colors.red, size: 50)),
          if (_showRecenterButton)
            Positioned(
              bottom: 30,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('이 위치로 재검색'),
                onPressed: () {
                  if (_currentMapCenter != null) {
                    // 버튼 클릭 시, 현재 지도 중앙 위치로 모든 것을 업데이트
                    _updateLocationAndMarkers(_currentMapCenter!); 
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
