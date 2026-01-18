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
import 'package:needsfine_app/screens/store_reviews_screen.dart';

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

  late final NaverGeocodingService _geocodingService;
  late final NaverSearchService _searchService;

  NaverPlace? _searchedPlace;
  Store? _matchedStore;
  NLatLng? _selectedPosition;
  bool _showBottomSheet = false;

  // ✅ 자동완성 관련 변수
  List<NaverPlace> _autocompleteResults = [];
  Timer? _debounce;
  bool _isSearching = false;

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

    // 외부(리뷰 등)에서 검색 요청이 왔을 때 리스너 연결
    searchTrigger.addListener(_handleExternalSearch);
  }

  // ✅ 외부(리뷰 상세 등)에서 넘어왔을 때 처리
  void _handleExternalSearch() async {
    final target = searchTrigger.value;
    if (target != null) {
      _searchController.text = target.query;
      searchTrigger.value = null; // 초기화
      FocusScope.of(context).unfocus();
      setState(() => _autocompleteResults = []); // 자동완성 닫기

      // 1. 좌표가 명확한 경우 (리뷰 상세에서 이동) -> 즉시 이동
      if (target.lat != null && target.lng != null) {
        final position = NLatLng(target.lat!, target.lng!);
        final dummyPlace = NaverPlace(
          title: target.query,
          category: '',
          address: '',
          roadAddress: '',
        );
        _selectPlaceWithCoordinates(dummyPlace, position);
      }
      // 2. 좌표가 없는 경우 (단순 검색어) -> 검색 실행
      else {
        _handleManualSearch(target.query);
      }
    }
  }

  @override
  void dispose() {
    searchTrigger.removeListener(_handleExternalSearch);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    final prefs = await SharedPreferences.getInstance();
    final userAddress = prefs.getString('user_address');
    if (userAddress != null && userAddress.isNotEmpty) {
      _moveMapToAddress(userAddress);
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

  // ✅ [기능 추가] 검색어 입력 시 자동완성 (Debounce 적용)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() => _autocompleteResults = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      try {
        final results = await _searchService.searchPlaces(query);
        if (mounted) {
          setState(() {
            // 최대 5개까지만 표시
            _autocompleteResults = results.take(5).toList();
          });
        }
      } catch (e) {
        debugPrint("검색 오류: $e");
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  // 검색 버튼 눌렀을 때 (키보드 완료 or 돋보기)
  Future<void> _handleManualSearch(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _autocompleteResults = []); // 검색 실행 시 자동완성 닫기

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
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("위치를 찾을 수 없습니다.")));
      }
    } catch (_) {}
  }

  // ✅ [수정] 핀 디자인 개선 (흰 배경 + 검은 글씨 + 보라 테두리)
  Widget _buildCustomMarkerWidget(String title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, // 흰색 배경
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
            // 니즈파인 컬러 테두리
            border: Border.all(color: const Color(0xFF9C7CFF), width: 2.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, color: Color(0xFF9C7CFF), size: 20),
              const SizedBox(width: 6),
              // 검은색 굵은 글씨로 변경하여 가독성 확보
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black, // 글씨색 검정
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        // 말풍선 꼬리
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 14,
            height: 10,
            color: const Color(0xFF9C7CFF),
          ),
        ),
      ],
    );
  }

  Future<void> _selectPlaceWithCoordinates(NaverPlace place, NLatLng position) async {
    _updateUI(place, position);
  }

  // 검색 결과 선택 시 (자동완성 or 리스트)
  Future<void> _selectPlace(NaverPlace place) async {
    setState(() {
      _searchController.text = place.cleanTitle; // 검색창에 선택한 가게 이름 표시
      _autocompleteResults = []; // 자동완성 목록 닫기
    });
    FocusScope.of(context).unfocus();

    try {
      // ✅ 도로명 주소 우선 사용 (정확도 향상)
      final queryAddr = place.roadAddress.isNotEmpty ? place.roadAddress : place.address;
      final response = await _geocodingService.searchAddress(queryAddr);

      if (response.addresses.isNotEmpty) {
        final addr = response.addresses.first;
        final position = NLatLng(double.parse(addr.y), double.parse(addr.x));
        _updateUI(place, position);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("정확한 좌표를 찾을 수 없습니다.")));
      }
    } catch (e) {
      debugPrint("Select Place Error: $e");
    }
  }

  void _updateUI(NaverPlace place, NLatLng position) async {
    Store? matched;
    try {
      matched = AppData().stores.firstWhere(
            (s) => s.name == place.cleanTitle || (s.latitude - position.latitude).abs() < 0.0005,
      );
    } catch (_) {
      matched = null;
    }

    setState(() {
      _searchedPlace = place;
      _matchedStore = matched;
      _selectedPosition = position;
      _showBottomSheet = true;
    });

    final controller = await _controller.future;
    controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: position, zoom: 16));

    final iconImage = await NOverlayImage.fromWidget(
      widget: _buildCustomMarkerWidget(place.cleanTitle),
      context: context,
    );
    final marker = NMarker(id: 'selected', position: position, icon: iconImage);

    controller.clearOverlays();
    controller.addOverlay(marker);
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

  Future<void> _navigateToWriteReview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          initialStoreName: _searchedPlace?.cleanTitle,
          initialAddress: _searchedPlace?.roadAddress.isNotEmpty == true
              ? _searchedPlace!.roadAddress
              : _searchedPlace?.address,
          initialLat: _selectedPosition?.latitude,
          initialLng: _selectedPosition?.longitude,
        ),
      ),
    );

    if (result == true) {
      if (_searchedPlace != null && _selectedPosition != null) {
        _selectPlaceWithCoordinates(_searchedPlace!, _selectedPosition!);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("소중한 리뷰 감사합니다!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      resizeToAvoidBottomInset: false, // 키보드 올라와도 지도 리사이즈 방지
      body: Stack(
        children: [
          // 1. 지도
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: _initialPosition,
              locationButtonEnable: true,
              indoorEnable: true,
            ),
            onMapReady: (controller) { if (!_controller.isCompleted) _controller.complete(controller); },
            onMapTapped: (_, __) {
              // 지도 빈 곳 터치 시 검색결과/자동완성 닫기
              if (_showBottomSheet) setState(() => _showBottomSheet = false);
              if (_autocompleteResults.isNotEmpty) setState(() => _autocompleteResults = []);
              FocusScope.of(context).unfocus();
            },
          ),

          // 2. 상단 검색창 + 자동완성 리스트
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 검색창
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged, // ✅ 입력 시 자동완성 호출
                        decoration: const InputDecoration(
                          hintText: '맛집 검색 (예: 광춘원)',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF9C7CFF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (val) => _handleManualSearch(val),
                      ),
                    ),

                    // ✅ 자동완성 리스트 (검색 결과가 있을 때만 표시)
                    if (_autocompleteResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 250), // 최대 높이 제한 (스크롤 가능)
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _autocompleteResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, index) {
                            final place = _autocompleteResults[index];
                            return ListTile(
                              dense: true,
                              title: Text(place.cleanTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                place.roadAddress.isNotEmpty ? place.roadAddress : place.address,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                _selectPlace(place); // 선택 시 해당 장소로 이동
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. 장소 정보 바텀 시트
          if (_showBottomSheet && _searchedPlace != null)
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.2,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
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
          Text(place.cleanTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (place.roadAddress.isNotEmpty || place.address.isNotEmpty)
            Text(place.roadAddress.isNotEmpty ? place.roadAddress : place.address, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          if (store != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildScoreBox("니즈파인 점수", store.needsFineScore.toStringAsFixed(1), const Color(0xFF9C7CFF)),
                _buildScoreBox("평균 신뢰도", "${store.averageTrustLevel}%", store.averageTrustLevel >= 50 ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Text("리뷰 ${store.reviewCount}개", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (store.allPhotos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: store.allPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        store.allPhotos[index],
                        width: 100, height: 100, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Text("등록된 사진이 없습니다", style: TextStyle(color: Colors.grey))),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StoreReviewsScreen(store: store)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF9C7CFF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("리뷰 보기", style: TextStyle(color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToWriteReview(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C7CFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("리뷰 쓰기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rate_review_outlined, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  const Text("아직 등록된 정보가 없습니다.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("'당신의 경험을 공유해주세요!'", style: TextStyle(color: Color(0xFF9C7CFF))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToWriteReview(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C7CFF),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("첫 번째 리뷰 작성하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  (place.roadAddress.isNotEmpty ? place.roadAddress : place.address).isNotEmpty
                      ? (place.roadAddress.isNotEmpty ? place.roadAddress : place.address)
                      : "위치 정보 없음 (좌표 기반)",
                  style: const TextStyle(color: Colors.black87)
              )),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, String value, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

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