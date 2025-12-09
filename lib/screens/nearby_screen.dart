import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final Set<Marker> _markers = {};
  final Key _mapKey = const ValueKey('NearbyGoogleMap');

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFirstLocationUpdate = true;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 거부되어 지도 기능을 사용할 수 없습니다.')),
        );
      }
    }
  }

  void _startListeningToLocation() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters.
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_isFirstLocationUpdate && mounted) {
          _moveCameraToCurrentLocation(position);
          _isFirstLocationUpdate = false;
        }
        _updateMarkerForCurrentLocation(position);
      },
      onError: (error) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('현재 위치를 추적하는 데 실패했습니다.')),
            );
          }
      }
    );
  }

  Future<void> _moveCameraToCurrentLocation(Position position) async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  void _updateMarkerForCurrentLocation(Position position) {
    final currentLocationMarker = Marker(
      markerId: const MarkerId('currentLocation'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: '현재 위치'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.add(currentLocationMarker);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('내 주변')),
      body: GoogleMap(
        key: _mapKey,
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition,
        onMapCreated: (controller) {
          if (!_controller.isCompleted) {
            _controller.complete(controller);
          }
        },
        markers: _markers,
        myLocationButtonEnabled: true,
        myLocationEnabled: true, // Shows the blue dot for the user's location
        zoomGesturesEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}
