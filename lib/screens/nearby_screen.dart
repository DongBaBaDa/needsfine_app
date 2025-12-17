import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  Set<Marker> _markers = {};
  LatLng? _currentMapCenter;

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFirstLocationUpdate = true;
  bool _showRecenterButton = false;
  String _displayLocation = '위치 확인 중...';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780), // Default to Seoul
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
        final newPosition = LatLng(position.latitude, position.longitude);
        if (_isFirstLocationUpdate && mounted) {
          _isFirstLocationUpdate = false;
          _updateLocationAndMarkers(newPosition, moveCamera: true);
        }
      },
      onError: (error) => _handleLocationError('현재 위치를 추적하는 데 실패했습니다.'),
    );
  }

  Set<Marker> _generateMarkers(LatLng center) {
    final newMarkers = <Marker>{};
    for (var store in AppData().stores) {
      final distance = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        store.latitude,
        store.longitude,
      );

      if (distance <= 2000) { // 2km 이내
        newMarkers.add(
          Marker(
            markerId: MarkerId(store.id),
            position: LatLng(store.latitude, store.longitude),
            infoWindow: InfoWindow(title: store.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet), 
          ),
        );
      }
    }
    return newMarkers;
  }

  Future<void> _moveCamera(LatLng position) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: 14.5)));
  }

  Future<void> _updateLocationAndMarkers(LatLng location, {bool moveCamera = false}) async {
    if (!mounted) return;

    if (moveCamera) {
      await _moveCamera(location);
    }

    String newDisplayLocation;
    try {
      // [최종 오류 수정] localeIdentifier 파라미터를 사용하지 않는 방식으로 호출합니다.
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        newDisplayLocation = "${p.locality} ${p.thoroughfare}".trim();
        if (newDisplayLocation.isEmpty) {
          newDisplayLocation = p.street ?? '주소 정보 없음';
        }
      } else {
        newDisplayLocation = '주소를 찾을 수 없음';
      }
    } catch (e) {
      newDisplayLocation = '주소 변환 실패';
      print("주소 변환 오류: $e");
    }

    final newMarkers = _generateMarkers(location);

    setState(() {
      _currentMapCenter = location;
      _displayLocation = newDisplayLocation;
      _markers = newMarkers;
      _showRecenterButton = false;
    });
  }

  Future<void> _navigateToAddressSearch() async {
    final result = await Navigator.pushNamed(context, '/address-search');
    if (result is LatLng) {
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.search, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Flexible(child: Text(_displayLocation, style: const TextStyle(fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                    ]),
                  )),
            )),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            markers: _markers,
            padding: const EdgeInsets.only(top: 50),
            myLocationButtonEnabled: true, 
            myLocationEnabled: true,
            onCameraMoveStarted: () {
              if (mounted) setState(() => _showRecenterButton = true);
            },
            onCameraMove: (position) => _currentMapCenter = position.target,
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
