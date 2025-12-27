import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

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
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFirstLocationUpdate = true;
  String _displayLocation = '강남구 역삼동'; 

  Store? _selectedStore;

  static const NCameraPosition _initialPosition = NCameraPosition(
    target: NLatLng(37.5008, 127.036), 
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
      final iconImage = await NOverlayImage.fromWidget(
        widget: _buildMarkerWidget(store), 
        context: context
      );

      final marker = NMarker(
        id: store.id,
        position: NLatLng(store.latitude, store.longitude),
        icon: iconImage,
        size: const Size(120, 50),
        anchor: const NPoint(0.5, 0.5),
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
  
  Widget _buildMarkerWidget(Store store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNeedsFinePurple, width: 2)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 10, child: Text("🇰🇷", style: TextStyle(fontSize: 12))),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(store.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
              const Text("100,000원", style: TextStyle(fontSize: 9, color: Colors.black)),
            ],
          )
        ],
      ),
    );
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
      // [수정됨] 한국어 주소 강제 변환 및 상세 주소 조합 로직 개선
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude, 
        location.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        
        String address = '';

        // 시/도 + 구/군 조합 우선
        if (p.locality != null && p.locality!.isNotEmpty) {
          address += "${p.locality} ";
        } else if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          address += "${p.administrativeArea} ";
        }

        // 동/읍/면 + 도로명 조합 우선
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          address += p.subLocality!;
        } else if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
          address += p.thoroughfare!;
        }

        // 그래도 비어있다면 전체 주소 사용
        if (address.trim().isEmpty) {
            address = p.street ?? "주소 정보 없음";
        }

        if(mounted) setState(() => _displayLocation = address.trim());
      }
    } on TimeoutException {
       if(mounted) setState(() => _displayLocation = "위치 확인 지연됨");
    } catch (e) {
      debugPrint("주소 변환 에러: $e");
      if(mounted) setState(() => _displayLocation = "위치 확인 불가");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/search'), icon: const Icon(Icons.search))
        ],
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
                  Row(children: [Chip(label: const Text('추천', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.orange, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)]),
                  const SizedBox(height: 4),
                  Text(store.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("영업중 · 02:00에 영업 종료", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(" ${store.userRating.toStringAsFixed(1)} · 방문자 리뷰 ${store.reviewCount}")]),
                  const SizedBox(height: 8),
                  const Row(children: [Text("100,000원", style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)), SizedBox(width: 8), Text("95,000원", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red))])
                ],
              ),
            ),
            Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedStore = null)))
          ],
        ),
      ),
    );
  }
}
