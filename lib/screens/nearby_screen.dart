import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
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

  final Completer<NaverMapController> _controller = Completer();
  NLatLng? _currentMapCenter;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFirstLocationUpdate = true;
  String _displayLocation = '강남구 역삼동'; // 임시 기본값

  Store? _selectedStore;

  static const NCameraPosition _initialPosition = NCameraPosition(
    target: NLatLng(37.5008, 127.036), // 역삼동 근처
    zoom: 15.0, 
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
      final controller = await _controller.future;
      _updateMarkers(controller, _initialPosition.target);
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
      onError: (error) => print("위치 추적 오류: $error"),
    );
  }

  Future<void> _updateMarkers(NaverMapController controller, NLatLng center) async {
    final newMarkers = <NMarker>{};
    
    for (var store in AppData().stores) {
      final marker = NMarker(
        id: store.id,
        position: NLatLng(store.latitude, store.longitude),
        caption: NOverlayCaption(text: store.name, minZoom: 14),
        // [수정] width, height 대신 size 파라미터 사용
        size: const Size(40, 50), 
      );
      
      marker.setOnTapListener((overlay) {
         setState(() {
           _selectedStore = store;
         });
         return true;
      });

      newMarkers.add(marker);
    }
    
    controller.clearOverlays();
    controller.addOverlayAll(newMarkers);
  }

  Future<void> _moveCamera(NLatLng position) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    final cameraUpdate = NCameraUpdate.scrollAndZoomTo(target: position, zoom: 15.0)..setAnimation(animation: NCameraAnimation.easing);
    await controller.updateCamera(cameraUpdate);
  }

  Future<void> _updateLocationAndMarkers(NLatLng location, {bool moveCamera = false}) async {
    if (!mounted) return;
    if (moveCamera) await _moveCamera(location);
    
    final controller = await _controller.future;
    await _updateMarkers(controller, location);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() => _displayLocation = "${p.locality} ${p.subLocality}");
      }
    } catch (e) { print("주소 변환 실패"); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: const BackButton(),
        actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/search'), icon: const Icon(Icons.search))],
      ),
      body: Stack(
        children: [
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: _initialPosition,
              locationButtonEnable: true, 
              scaleBarEnable: false,
              logoClickEnable: false,
            ),
            onMapReady: (controller) async {
              if (!_controller.isCompleted) _controller.complete(controller);
              if (!(await Permission.location.isGranted)){
                 _updateMarkers(controller, _initialPosition.target);
              }
            },
            onMapTapped: (point, latLng) {
              setState(() {
                _selectedStore = null;
              });
            },
          ),
          if (_selectedStore != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildStoreInfoSheet(_selectedStore!),
            )
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network('https://via.placeholder.com/150', width: 100, height: 100, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: const Text('추천'), backgroundColor: Colors.orange, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      const SizedBox(width: 4),
                      Chip(label: const Text('인기HOT'), backgroundColor: Colors.red, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("영업중 · 02:00에 영업 종료", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(" ${store.userRating.toStringAsFixed(1)} · 방문자 리뷰 ${store.reviewCount}")]),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text("100,000원", style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                      SizedBox(width: 8),
                      Text("95,000원", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  )
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedStore = null)),
            )
          ],
        ),
      ),
    );
  }
}
