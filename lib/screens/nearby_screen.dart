import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; // 네이버 지도 패키지
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
// 구글 지도 LatLng 호환을 위해 별칭 사용 (나중에 AddressSearchScreen도 네이버로 바꾸면 제거 가능)
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps; 

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

  final Completer<NaverMapController> _controller = Completer();
  // 마커는 컨트롤러를 통해 관리하므로 Set<Marker> 변수는 제거하고, 현재 상태 유지를 위한 리스트만 사용 가능하나
  // 네이버 맵은 controller.addOverlay로 즉시 반영합니다.
  
  NLatLng? _currentMapCenter;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFirstLocationUpdate = true;
  bool _showRecenterButton = false;
  String _displayLocation = '위치 확인 중...';

  // 초기 위치 (서울 시청)
  static const NCameraPosition _initialPosition = NCameraPosition(
    target: NLatLng(37.5665, 126.9780),
    zoom: 14.0, 
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
        final newPosition = NLatLng(position.latitude, position.longitude);
        if (_isFirstLocationUpdate && mounted) {
          _isFirstLocationUpdate = false;
          _updateLocationAndMarkers(newPosition, moveCamera: true);
        }
      },
      onError: (error) => _handleLocationError('현재 위치를 추적하는 데 실패했습니다.'),
    );
  }

  // 마커 생성 및 지도에 추가
  Future<void> _updateMarkers(NaverMapController controller, NLatLng center) async {
    final newMarkers = <NMarker>{};
    
    for (var store in AppData().stores) {
      final distance = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        store.latitude,
        store.longitude,
      );

      if (distance <= 2000) { // 2km 이내
        final marker = NMarker(
          id: store.id,
          position: NLatLng(store.latitude, store.longitude),
          iconTintColor: Colors.deepPurpleAccent, // Violet 색상 효과
        );
        
        // 마커 클릭 시 정보창 표시
        marker.setOnTapListener((overlay) {
           final infoWindow = NInfoWindow.onMarker(id: marker.info.id, text: store.name);
           marker.openInfoWindow(infoWindow);
           return true;
        });

        newMarkers.add(marker);
      }
    }
    
    // 기존 마커 지우고 새로 추가 (효율성을 위해 diff를 계산할 수도 있지만 간단히 구현)
    controller.clearOverlays();
    controller.addOverlayAll(newMarkers);
  }

  Future<void> _moveCamera(NLatLng position) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    
    final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
      target: position,
      zoom: 14.5,
    )..setAnimation(animation: NCameraAnimation.easing);
    
    await controller.updateCamera(cameraUpdate);
  }

  Future<void> _updateLocationAndMarkers(NLatLng location, {bool moveCamera = false}) async {
    if (!mounted) return;

    if (moveCamera) {
      await _moveCamera(location);
    }
    
    // 마커 업데이트
    if (_controller.isCompleted) {
      final controller = await _controller.future;
      await _updateMarkers(controller, location);
    }

    String newDisplayLocation;
    try {
      // 좌표 -> 주소 변환 (Reverse Geocoding)
      // 네이버 SDK 자체 기능을 쓸 수도 있지만, 기존 geocoding 패키지를 그대로 사용 (플랫폼 종속적)
      // 정확도를 위해 추후 네이버 Reverse Geocoding API 호출로 변경 권장
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addressParts = [p.administrativeArea, p.locality, p.subLocality, p.thoroughfare, p.subThoroughfare]
            .where((part) => part != null && part.isNotEmpty)
            .join(' ');
        newDisplayLocation = addressParts.isEmpty ? (p.street ?? '주소 정보 없음') : addressParts;
      } else {
        newDisplayLocation = '주소를 찾을 수 없음';
      }
    } catch (e) {
      newDisplayLocation = '주소 변환 실패';
      print("주소 변환 오류: $e");
    }

    setState(() {
      _currentMapCenter = location;
      _displayLocation = newDisplayLocation;
      _showRecenterButton = false;
    });
  }

  Future<void> _navigateToAddressSearch() async {
    final result = await Navigator.pushNamed(context, '/address-search');
    
    // Google LatLng가 반환될 경우 처리
    if (result is google_maps.LatLng) {
       final nLatLng = NLatLng(result.latitude, result.longitude);
       _updateLocationAndMarkers(nLatLng, moveCamera: true);
    } else if (result is NLatLng) {
       _updateLocationAndMarkers(result, moveCamera: true);
    }
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
        title: const Text('현재 위치'),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight - 10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GestureDetector(
                  onTap: _navigateToAddressSearch,
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: _displayLocation));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('주소가 복사되었습니다.')),
                    );
                  },
                  child: Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.search, size: 20, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_displayLocation, 
                          style: const TextStyle(fontSize: 14, color: Colors.black87), 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  )),
            )),
      ),
      body: Stack(
        children: [
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: _initialPosition,
              locationButtonEnable: true, // 현위치 버튼 활성화
              scaleBarEnable: false,
            ),
            onMapReady: (controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
                // 맵 로드 시 초기 마커 생성 (현재 위치 기준이 없다면 초기 위치 기준)
                if (_currentMapCenter == null) {
                  _updateMarkers(controller, _initialPosition.target);
                }
              }
            },
            onCameraChange: (reason, animated) {
               // 카메라 이동 시작 시 재검색 버튼 표시 로직
               // 네이버 맵은 moveStarted 이벤트가 명시적이지 않을 수 있어 change로 감지
               if (reason == NCameraUpdateReason.gesture) {
                 if (mounted && !_showRecenterButton) {
                   setState(() => _showRecenterButton = true);
                 }
               }
            },
            onCameraIdle: () async {
               if (_controller.isCompleted) {
                 final controller = await _controller.future;
                 final cameraPosition = await controller.getCameraPosition();
                 _currentMapCenter = cameraPosition.target;
               }
            },
          ),
          const IgnorePointer(child: Center(child: Icon(Icons.location_pin, color: Colors.red, size: 50))),
          if (_showRecenterButton)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('이 위치로 재검색'),
                  onPressed: () {
                    if (_currentMapCenter != null) {
                      _updateLocationAndMarkers(_currentMapCenter!); 
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
