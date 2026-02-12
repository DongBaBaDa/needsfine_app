// lib/screens/nearby_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/services/naver_search_service.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/core/search_trigger.dart'; // ✅ 전역 트리거
import 'package:needsfine_app/screens/write_review_screen.dart';
import 'package:needsfine_app/screens/store_reviews_screen.dart';
import 'package:needsfine_app/screens/store_info_screen.dart'; // ✅ 매장 정보 화면

// ✅ 서비스 임포트 추가
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/services/naver_search_service.dart'; // ✅ Import added for GeocodingService
import 'package:needsfine_app/models/ranking_models.dart'; // ✅ 모델 임포트 추가

// ✅ Supabase 조회
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ 다국어 패키지 임포트
import 'package:needsfine_app/l10n/app_localizations.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 탭 이동 시 지도 상태 유지

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
    target: NLatLng(36.5, 127.8), // 대한민국 중심
    zoom: 7.0, // 전국 보기
  );

  // ✅ Supabase
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // ✅ 클러스터 이미지 캐시 (성능 최적화)
  final Map<String, NOverlayImage> _clusterImageCache = {};
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 캐시 정리 (예: 언어 변경 시)
    _clusterImageCache.clear();
  }

  // ✅ 매장 상태 관리 변수들 (UI 직결)
  bool _isStoreSaved = false;
  bool _isSavingStore = false;
  int _storeSaveCount = 0;
  int _storeCommentCount = 0;

  // ✅ 화면 표시용 상태 (점수, 신뢰도, 태그)
  double _displayScore = 0.0;
  int _displayTrust = 0;
  List<String> _displayTags = []; // ✅ 태그 리스트 추가

  // ✅ 클러스터링 관련 변수
  List<StoreRanking> _allStoreRankings = [];
  double _currentZoom = 7.0;
  Set<NOverlay> _clusterOverlays = {};
  Timer? _clusterDebounce;

  // ✅ 좌표 트리거로 들어왔을 때 주소 복구용
  String? _resolvedStoreName;
  String? _resolvedStoreAddress;

  @override
  void initState() {
    super.initState();
    _geocodingService = NaverGeocodingService();
    _searchService = NaverSearchService();
    _initializeMap();

    // ✅ 외부 검색 요청 리스너 연결
    searchTrigger.addListener(_handleExternalSearch);
  }

  // ✅ 외부 요청 처리 로직
  void _handleExternalSearch() async {
    final target = searchTrigger.value;
    if (target != null) {
      _searchController.text = target.query;
      searchTrigger.value = null; // 트리거 초기화
      FocusScope.of(context).unfocus();

      if (mounted) {
        setState(() {
          _autocompleteResults = [];
          _resetStoreState();
        });
      }

      // 1) 좌표가 명확한 경우 -> 즉시 이동
      if (target.lat != null && target.lng != null && target.lat != 0 && target.lng != 0) {
        _moveToCoordinates(target.query, target.lat!, target.lng!);
      }
      // 2) 좌표가 없는 경우 -> DB에서 좌표 찾기 시도 또는 검색 실행
      else {
        final dbCoords = await _findCoordinatesFromDB(target.query);
        if (dbCoords != null) {
          _moveToCoordinates(target.query, dbCoords.latitude, dbCoords.longitude);
        } else {
          _handleManualSearch(target.query);
        }
      }
    }
  }

  // ✅ 상태 초기화 헬퍼 함수
  void _resetStoreState() {
    _resolvedStoreName = null;
    _resolvedStoreAddress = null;
    _matchedStore = null;
    _isStoreSaved = false;
    _storeSaveCount = 0;
    _storeCommentCount = 0;
    _displayScore = 0.0;
    _displayTrust = 0;
    _displayTags = [];
  }

  // ✅ DB에서 가게 이름으로 좌표 찾기
  Future<NLatLng?> _findCoordinatesFromDB(String storeName) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('store_lat, store_lng')
          .eq('store_name', storeName)
          .neq('store_lat', 0)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final lat = response['store_lat'];
        final lng = response['store_lng'];
        if (lat != null && lng != null) {
          return NLatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint("DB 좌표 조회 실패: $e");
    }
    return null;
  }

  // ✅ 좌표로 바로 이동하는 내부 함수
  void _moveToCoordinates(String name, double lat, double lng) {
    final position = NLatLng(lat, lng);
    final dummyPlace = NaverPlace(
      title: name,
      category: '',
      address: '',
      roadAddress: '',
    );
    _selectPlaceWithCoordinates(dummyPlace, position);
  }

  @override
  void dispose() {
    searchTrigger.removeListener(_handleExternalSearch);
    _searchController.dispose();
    _debounce?.cancel();
    _clusterDebounce?.cancel();
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
    
    // ✅ [추가] 랭킹에 있는 매장 마커 표시
    _fetchAndShowStoreMarkers();
  }

  // ✅ [New] 리뷰 테이블에서 직접 매장 좌표 + 점수 로드 → 클러스터 표시
  Future<void> _fetchAndShowStoreMarkers() async {
    print("🗺️🗺️🗺️ _fetchAndShowStoreMarkers 시작!");
    try {
      // reviews 테이블에서 직접 좌표 포함 조회
      final response = await _supabase
          .from('reviews')
          .select('id, store_name, store_address, store_lat, store_lng, needsfine_score, trust_level, is_hidden');

      final List<dynamic> data = response as List<dynamic>;
      print("🗺️ 리뷰 원본 데이터 로드: ${data.length}건");

      if (data.isEmpty) {
        print("🗺️ 리뷰 데이터 없음!");
        return;
      }

      // ★ 좌표 없는 리뷰를 지오코딩으로 자동 보정
      final missingCoords = data.where((row) {
        final map = row as Map<String, dynamic>;
        final lat = map['store_lat'];
        final lng = map['store_lng'];
        final addr = map['store_address']?.toString() ?? '';
        return (lat == null || lat == 0) && addr.isNotEmpty;
      }).toList();

      if (missingCoords.isNotEmpty) {
        // 🔥 [최적화] 지오코딩 백그라운드 실행 (await 제거하여 지도 로딩 차단 방지)
        _backfillCoordinates(missingCoords);
      }

      // 유효한 데이터만 필터 (is_hidden=false, 좌표 있음)
      final validData = data.where((row) {
        final map = row as Map<String, dynamic>;
        final lat = (map['store_lat'] ?? 0);
        final lng = (map['store_lng'] ?? 0);
        final hidden = map['is_hidden'] ?? false;
        return hidden == false && lat != 0 && lng != 0;
      }).toList();

      print("🗺️ 필터 후 유효 리뷰: ${validData.length}건 (원본 ${data.length}건)");

      if (validData.isEmpty) {
        print("🗺️ 유효한 좌표가 있는 리뷰 없음!");
        return;
      }

      // 매장별 그룹핑
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in validData) {
        final map = row as Map<String, dynamic>;
        final name = map['store_name']?.toString() ?? '';
        grouped.putIfAbsent(name, () => []).add(map);
      }

      // StoreRanking 목록 생성
      _allStoreRankings = grouped.entries.map((entry) {
        final reviews = entry.value;
        final first = reviews.first;
        double avgScore = 0;
        double avgTrust = 0;
        for (final r in reviews) {
          avgScore += (r['needsfine_score'] ?? 0).toDouble();
          avgTrust += (r['trust_level'] ?? 0).toDouble();
        }
        avgScore /= reviews.length;
        avgTrust /= reviews.length;

        return StoreRanking(
          storeName: entry.key,
          avgScore: avgScore,
          avgUserRating: 0,
          reviewCount: reviews.length,
          avgTrust: avgTrust,
          rank: 0,
          address: first['store_address']?.toString(),
          lat: (first['store_lat'] ?? 0).toDouble(),
          lng: (first['store_lng'] ?? 0).toDouble(),
        );
      }).toList();

      print("🗺️ ✅ 매장 ${_allStoreRankings.length}개 로드 완료!");
      _updateClusters();
    } catch (e, stack) {
      print("❌❌❌ 매장 마커 로드 실패: $e");
      print("❌ 스택: $stack");
    }
  }

  // ✅ [New] 백그라운드 지오코딩 보정
  Future<void> _backfillCoordinates(List<dynamic> missingCoords) async {
    print("🗺️ [Background] 좌표 없는 리뷰 ${missingCoords.length}건 → 지오코딩 보정 시작");
    final geocodingService = NaverGeocodingService();
    int fixed = 0;
    bool needsUpdate = false;

    for (final row in missingCoords) {
      final map = row as Map<String, dynamic>;
      final addr = map['store_address']?.toString() ?? '';
      final id = map['id'];
      try {
        final result = await geocodingService.searchAddress(addr);
        if (result.addresses.isNotEmpty) {
          final lat = double.tryParse(result.addresses.first.y);
          final lng = double.tryParse(result.addresses.first.x);
          if (lat != null && lng != null) {
            await _supabase.from('reviews').update({
              'store_lat': lat,
              'store_lng': lng,
            }).eq('id', id);
            
            // 메모리 데이터 업데이트
            map['store_lat'] = lat;
            map['store_lng'] = lng;
            fixed++;
            needsUpdate = true;
            print("🗺️ ✅ [Background] 보정 완료: ${map['store_name']} → ($lat, $lng)");
          }
        }
      } catch (e) {
        print("🗺️ ⚠️ [Background] 지오코딩 실패 (${map['store_name']}): $e");
      }
    }
    print("🗺️ [Background] 좌표 보정 완료: $fixed/${missingCoords.length}건");
    
    // 보정된 데이터가 있으면 마커 갱신
    if (needsUpdate && mounted) {
      // 데이터 다시 로드 대신 메모리에서 StoreRanking 재생성 후 갱신
      _fetchAndShowStoreMarkers(); 
    }
  }

  // ✅ 줌 변경 시 호출 (debounced)
  void _onCameraChange(NCameraUpdateReason reason, bool isGestureActive) async {
    _clusterDebounce?.cancel();
    _clusterDebounce = Timer(const Duration(milliseconds: 100), () async {
      try {
        final controller = await _controller.future;
        final position = await controller.getCameraPosition();
        final newZoom = position.zoom;
        // 줌 레벨 범주가 달라졌을 때만 클러스터 갱신
        final oldLevel = _getClusterLevel(_currentZoom);
        final newLevel = _getClusterLevel(newZoom);
        _currentZoom = newZoom;
        if (oldLevel != newLevel) {
          debugPrint("🗺️ 줌 변경: $_currentZoom (level $oldLevel → $newLevel)");
          _updateClusters();
        }
      } catch (_) {}
    });
  }

  int _getClusterLevel(double zoom) {
    if (zoom >= 14) return 4; // 개별 매장
    if (zoom >= 11) return 3; // 읍면동
    if (zoom >= 8) return 2;  // 시군구
    if (zoom >= 6) return 1;  // 시도
    return 0;                  // 대한민국 전체
  }

  // ✅ 주소에서 행정구역 토큰 추출
  String _getClusterKey(String? address, int level) {
    if (address == null || address.isEmpty) return '기타';
    final tokens = address.split(' ');
    switch (level) {
      case 0: // 대한민국 전체
        return '대한민국';
      case 1: // 시·도
        return tokens.isNotEmpty ? tokens[0] : '기타';
      case 2: // 시·군·구
        return tokens.length >= 2 ? '${tokens[0]} ${tokens[1]}' : tokens[0];
      case 3: // 읍·면·동
        return tokens.length >= 3 ? '${tokens[0]} ${tokens[1]} ${tokens[2]}' : (tokens.length >= 2 ? '${tokens[0]} ${tokens[1]}' : tokens[0]);
      default:
        return address;
    }
  }

  // ✅ 클러스터용 짧은 표시명
  String _getClusterDisplayName(String key, int level) {
    final tokens = key.split(' ');
    switch (level) {
      case 0: // 대한민국 전체
        return '대한민국';
      case 1:
        // "서울특별시" → "서울", "전라남도" → "전남" 등 표준 약어 적용 (다국어 지원)
        final t = tokens.last;
        return _abbreviateRegion(t);
      case 2:
        return tokens.length >= 2 ? tokens[1] : tokens[0];
      case 3:
        return tokens.length >= 3 ? tokens[2] : tokens.last;
      default:
        return key;
    }
  }

  // ✅ 행정구역 표준 약어 변환 (다국어 지원)
  String _abbreviateRegion(String name) {
    if (!mounted) return name;
    final l10n = AppLocalizations.of(context)!;
    
    final Map<String, String> regionMap = {
      '대한민국': l10n.regionKorea,
      '서울특별시': l10n.regionSeoul,
      '서울': l10n.regionSeoul,
      '부산광역시': l10n.regionBusan,
      '부산': l10n.regionBusan,
      '대구광역시': l10n.regionDaegu,
      '대구': l10n.regionDaegu,
      '인천광역시': l10n.regionIncheon,
      '인천': l10n.regionIncheon,
      '광주광역시': l10n.regionGwangju,
      '광주': l10n.regionGwangju,
      '대전광역시': l10n.regionDaejeon,
      '대전': l10n.regionDaejeon,
      '울산광역시': l10n.regionUlsan,
      '울산': l10n.regionUlsan,
      '세종특별자치시': l10n.regionSejong,
      '세종': l10n.regionSejong,
      '경기도': l10n.regionGyeonggi,
      '경기': l10n.regionGyeonggi,
      '강원특별자치도': l10n.regionGangwon,
      '강원도': l10n.regionGangwon,
      '강원': l10n.regionGangwon,
      '충청북도': l10n.regionChungbuk,
      '충북': l10n.regionChungbuk,
      '충청남도': l10n.regionChungnam,
      '충남': l10n.regionChungnam,
      '전라북도': l10n.regionJeonbuk,
      '전북특별자치도': l10n.regionJeonbuk,
      '전북': l10n.regionJeonbuk,
      '전라남도': l10n.regionJeonnam,
      '전남': l10n.regionJeonnam,
      '경상북도': l10n.regionGyeongbuk,
      '경북': l10n.regionGyeongbuk,
      '경상남도': l10n.regionGyeongnam,
      '경남': l10n.regionGyeongnam,
      '제주특별자치도': l10n.regionJeju,
      '제주도': l10n.regionJeju,
      '제주': l10n.regionJeju,
    };
    
    // 1차 매핑 시도
    if (regionMap.containsKey(name)) return regionMap[name]!;
    
    // "전라남도" -> "전남" 같은 축약형에 대한 매핑이 없을 경우를 대비해,
    // 정규식으로 "도, 시" 제거 후 다시 매핑 시도해볼 수도 있음.
    // 하지만 현재 맵퍼가 대부분 커버함.
    
    return name.replaceAll(RegExp(r'(특별시|광역시|특별자치시|특별자치도|도)$'), '');
  }

  // ✅ 핵심: 줌 레벨에 따라 클러스터/개별 마커 갱신
  Future<void> _updateClusters() async {
    if (_allStoreRankings.isEmpty) {
      debugPrint("🗺️ _updateClusters: 매장 데이터 없음, 스킵");
      return;
    }

    // ★ 핵심 수정: await로 컨트롤러 대기 (기존: isCompleted 체크 후 return → 초기 로드 시 마커 안 뜸)
    final controller = await _controller.future;

    // 기존 클러스터 오버레이 제거
    for (final overlay in _clusterOverlays) {
      controller.deleteOverlay(overlay.info);
    }
    _clusterOverlays.clear();

    final validStores = _allStoreRankings.where((s) => s.lat != null && s.lng != null && s.lat != 0 && s.lng != 0).toList();
    if (validStores.isEmpty) {
      debugPrint("🗺️ _updateClusters: 유효한 좌표 매장 없음!");
      return;
    }

    final level = _getClusterLevel(_currentZoom);

    if (level == 4) {
      // ============ 개별 매장 핀 ============
      final markers = <NMarker>{};
      for (final store in validStores) {
        final position = NLatLng(store.lat!, store.lng!);
        final iconImage = await NOverlayImage.fromWidget(
          widget: _buildCustomMarkerWidget(store.storeName, score: store.avgScore),
          context: context,
        );
        final marker = NMarker(
          id: 'cluster_store_${store.storeName}_${store.lat}_${store.lng}',
          position: position,
          icon: iconImage,
        );
        marker.setOnTapListener((overlay) {
          _selectPlaceWithCoordinates(
            NaverPlace(
              title: store.storeName,
              address: store.address ?? '',
              roadAddress: store.address ?? '',
              category: '',
            ),
            position,
          );
        });
        markers.add(marker);
      }
      _clusterOverlays = markers.cast<NOverlay>().toSet();
      controller.addOverlayAll(markers);
    } else {
      // ============ 클러스터 배지 ============
      final groups = <String, List<StoreRanking>>{};
      for (final store in validStores) {
        final key = _getClusterKey(store.address, level);
        groups.putIfAbsent(key, () => []).add(store);
      }

      final markers = <NMarker>{};
      for (final entry in groups.entries) {
        final stores = entry.value;
        final displayName = _getClusterDisplayName(entry.key, level);

        // 클러스터 중심: 그룹 내 매장 좌표 평균
        double avgLat = 0, avgLng = 0;
        for (final s in stores) {
          avgLat += s.lat!;
          avgLng += s.lng!;
        }
        avgLat /= stores.length;
        avgLng /= stores.length;

        final position = NLatLng(avgLat, avgLng);
        final cacheKey = "${displayName}_${stores.length}";
        
        NOverlayImage iconImage;
        if (_clusterImageCache.containsKey(cacheKey)) {
          iconImage = _clusterImageCache[cacheKey]!;
        } else {
          iconImage = await NOverlayImage.fromWidget(
            widget: _buildClusterMarkerWidget(displayName, stores.length),
            context: context,
          );
          _clusterImageCache[cacheKey] = iconImage;
        }

        final marker = NMarker(
          id: 'cluster_group_${entry.key.hashCode}',
          position: position,
          icon: iconImage,
        );

        // 탭 시 해당 클러스터 영역으로 줌 인
        marker.setOnTapListener((overlay) async {
          double targetZoom;
          if (level == 0) targetZoom = 7;       // 대한민국 → 시도
          else if (level == 1) targetZoom = 9;   // 시도 → 시군구
          else if (level == 2) targetZoom = 12;  // 시군구 → 읍면동
          else targetZoom = 14;                   // 읍면동 → 개별

          final ctrl = await _controller.future;
          ctrl.updateCamera(
            NCameraUpdate.scrollAndZoomTo(
              target: position,
              zoom: targetZoom,
            )..setAnimation(animation: NCameraAnimation.easing, duration: const Duration(milliseconds: 500)),
          );
        });

        markers.add(marker);
      }
      _clusterOverlays = markers.cast<NOverlay>().toSet();
      controller.addOverlayAll(markers);
    }
  }

  // ✅ 클러스터 마커 위젯: 원형 배지 + 이름 + 개수
  Widget _buildClusterMarkerWidget(String regionName, int count) {
    // 개수에 따라 크기 조절
    final double size = count >= 20 ? 70 : (count >= 5 ? 60 : 50);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9C7CFF), Color(0xFF7B5FE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C7CFF).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
            ],
          ),
          child: Text(
            regionName,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D3A),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
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

  Future<void> _handleManualSearch(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();

    // 🔴 새로운 검색 시 상태 초기화
    setState(() {
      _autocompleteResults = [];
      _resetStoreState();
    });

    final places = await _searchService.searchPlaces(query);

    // ✅ [문제 2 해결] 검색 결과 중 이름이 정확히 일치하는 것이 있다면 즉시 선택
    NaverPlace? exactMatch;
    try {
      exactMatch = places.firstWhere((p) => p.cleanTitle == query);
    } catch (_) {
      exactMatch = null;
    }

    if (exactMatch != null) {
      _selectPlace(exactMatch); // 즉시 이동
    } else if (places.isEmpty) {
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.locationNotFound)));
      }
    } catch (_) {}
  }

  Widget _buildCustomMarkerWidget(String title, {double? score}) {
    final displayTitle = score != null 
        ? "$title (${score.toStringAsFixed(1)})" 
        : title;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
            border: Border.all(color: const Color(0xFF9C7CFF), width: 2.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, color: Color(0xFF9C7CFF), size: 20),
              const SizedBox(width: 6),
              Text(
                displayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
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

  String _normalizedAddress(NaverPlace place) {
    final raw = (place.roadAddress.isNotEmpty ? place.roadAddress : place.address);
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _effectiveStoreName(NaverPlace place) {
    final resolved = _resolvedStoreName;
    if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
    return place.cleanTitle;
  }

  String _effectiveStoreAddress(NaverPlace place) {
    final resolved = _resolvedStoreAddress;
    if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
    return _normalizedAddress(place);
  }

  String _displayAddress(NaverPlace place) {
    final resolved = _resolvedStoreAddress;
    if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
    final raw = (place.roadAddress.isNotEmpty ? place.roadAddress : place.address).trim();
    return raw;
  }

  Future<void> _selectPlaceWithCoordinates(NaverPlace place, NLatLng position) async {
    _updateUI(place, position);
  }

  Future<void> _selectPlace(NaverPlace place) async {
    // 🔴 상태 초기화
    setState(() {
      _searchController.text = place.cleanTitle;
      _autocompleteResults = [];
      _resetStoreState();
    });
    FocusScope.of(context).unfocus();

    try {
      final queryAddr = place.roadAddress.isNotEmpty ? place.roadAddress : place.address;
      final response = await _geocodingService.searchAddress(queryAddr);

      if (response.addresses.isNotEmpty) {
        final addr = response.addresses.first;
        final position = NLatLng(double.parse(addr.y), double.parse(addr.x));
        _updateUI(place, position);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.preciseLocationNotFound)));
      }
    } catch (e) {
      debugPrint("Select Place Error: $e");
    }
  }

  // ✅ Store 생성자 (유연하게 처리)
  Store _createStoreFlexible({
    required String name,
    required double latitude,
    required double longitude,
    required double needsFineScore,
    required int avgTrust,
    required int reviewCount,
    required List<String> allPhotos,
    required String address,
  }) {
    // Store 모델에 avgTrust 필드가 없어도 UI는 _displayTrust로 처리하므로 안전
    return Store(
      id: 'temp_id_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: '음식점',
      tags: [],
      latitude: latitude,
      longitude: longitude,
      address: address,
      userRating: 0.0,
      needsFineScore: needsFineScore,
      reviewCount: reviewCount,
      reviews: [],
    );
  }

  // ✅ [수정] 헬퍼 메소드 복구 (Store 모델에 맞게 처리)
  int _getStoreReviewCount(Store s) {
    final d = s as dynamic;
    try { return (d.reviewCount as num).toInt(); } catch (_) { return 0; }
  }

  List<String> _getStorePhotos(Store s) {
    // DB에서 가져온 사진 리스트를 반환할 수도 있으나, Store 모델에 없다면 빈 리스트
    return [];
  }

  // ✅ [복구] ID 해결 로직 (가장 많이 사용된 주소 찾기 등)
  Future<void> _ensureResolvedIdentity(NaverPlace place, NLatLng position) async {
    if (_resolvedStoreName == place.cleanTitle && (_resolvedStoreAddress?.trim().isNotEmpty ?? false)) return;

    final rawAddr = _normalizedAddress(place);
    if (rawAddr.isNotEmpty) {
      if (mounted) {
        setState(() {
          _resolvedStoreName ??= place.cleanTitle;
          _resolvedStoreAddress ??= rawAddr;
        });
      }
      return;
    }

    try {
      final name = place.cleanTitle;
      final eps = 0.002;

      final rowsByName = await _supabase
          .from('reviews')
          .select('store_name, store_address, is_hidden')
          .eq('store_name', name);

      List list = (rowsByName is List) ? rowsByName : [];

      if (list.isEmpty) {
        final rowsByPos = await _supabase
            .from('reviews')
            .select('store_name, store_address, is_hidden, store_lat, store_lng')
            .gte('store_lat', position.latitude - eps)
            .lte('store_lat', position.latitude + eps)
            .gte('store_lng', position.longitude - eps)
            .lte('store_lng', position.longitude + eps);

        list = (rowsByPos is List) ? rowsByPos : [];
      }

      if (list.isEmpty) return;

      final addrCount = <String, int>{};
      String? bestName;
      for (final r in list) {
        final m = r as Map;
        final hidden = m['is_hidden'];
        if (hidden is bool && hidden == true) continue;

        final sn = (m['store_name'] ?? '').toString().trim();
        final sa = (m['store_address'] ?? '').toString().trim();

        if (bestName == null && sn.isNotEmpty) bestName = sn;
        if (sa.isNotEmpty) {
          addrCount[sa] = (addrCount[sa] ?? 0) + 1;
        }
      }

      String? bestAddr;
      int best = -1;
      addrCount.forEach((k, v) {
        if (v > best) {
          best = v;
          bestAddr = k;
        }
      });

      if (mounted) {
        setState(() {
          if (bestName != null && bestName!.isNotEmpty) _resolvedStoreName = bestName;
          if (bestAddr != null && bestAddr!.isNotEmpty) _resolvedStoreAddress = bestAddr;
        });
      }
    } catch (e) {
      debugPrint("_ensureResolvedIdentity 실패: $e");
    }
  }

  Future<void> _loadStoreCountsAndState(NaverPlace place, NLatLng position) async {
    await _ensureResolvedIdentity(place, position);

    final userId = _supabase.auth.currentUser?.id;
    final name = _effectiveStoreName(place);
    final addr = _effectiveStoreAddress(place);

    try {
      dynamic rows;
      if (addr.isNotEmpty) {
        rows = await _supabase
            .from('store_saves')
            .select('id')
            .eq('store_name', name)
            .eq('store_address', addr);
      } else {
        rows = await _supabase
            .from('store_saves')
            .select('id')
            .eq('store_name', name);
      }

      final c = (rows is List) ? rows.length : 0;
      if (mounted) setState(() => _storeSaveCount = c);
    } catch (e) {
      if (mounted) setState(() => _storeSaveCount = 0);
    }

    try {
      if (userId == null) {
        if (mounted) setState(() => _isStoreSaved = false);
      } else {
        dynamic saved;
        if (addr.isNotEmpty) {
          saved = await _supabase
              .from('store_saves')
              .select('id')
              .eq('user_id', userId)
              .eq('store_name', name)
              .eq('store_address', addr)
              .maybeSingle();
        } else {
          saved = await _supabase
              .from('store_saves')
              .select('id')
              .eq('user_id', userId)
              .eq('store_name', name)
              .maybeSingle();
        }
        if (mounted) setState(() => _isStoreSaved = saved != null);
      }
    } catch (e) {
      if (mounted) setState(() => _isStoreSaved = false);
    }

    try {
      dynamic rows = await _supabase
          .from('reviews')
          .select('comment_count, is_hidden, store_lat, store_lng, store_name, store_address')
          .eq('store_name', name);

      List list = (rows is List) ? rows : [];

      // 주소 필터링 없이 이름으로만 댓글 수 집계 (RankingScreen과 통일)
      int sum = 0;
      for (final r in list) {
        final m = r as Map;
        final hidden = m['is_hidden'];
        if (hidden is bool && hidden == true) continue;

        final v = m['comment_count'];
        if (v is int) sum += v;
        if (v is num) sum += v.toInt();
      }

      if (mounted) setState(() => _storeCommentCount = sum);
    } catch (e) {
      if (mounted) setState(() => _storeCommentCount = 0);
    }
  }

  Future<void> _toggleStoreSave() async {
    if (_isSavingStore) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.loginRequired)));
      }
      return;
    }

    final place = _searchedPlace;
    final pos = _selectedPosition;
    if (place == null || pos == null) return;

    await _ensureResolvedIdentity(place, pos);

    final name = _effectiveStoreName(place);
    final addr = _effectiveStoreAddress(place);

    if (addr.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.verifyingAddress)),
        );
      }
      return;
    }

    final next = !_isStoreSaved;

    setState(() {
      _isSavingStore = true;
      _isStoreSaved = next;
      _storeSaveCount += next ? 1 : -1;
      if (_storeSaveCount < 0) _storeSaveCount = 0;
    });

    try {
      if (next) {
        await _supabase.from('store_saves').insert({
          'user_id': userId,
          'store_name': name,
          'store_address': addr,
        });
      } else {
        await _supabase
            .from('store_saves')
            .delete()
            .eq('user_id', userId)
            .eq('store_name', name)
            .eq('store_address', addr);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStoreSaved = !next;
          _storeSaveCount += next ? -1 : 1;
          if (_storeSaveCount < 0) _storeSaveCount = 0;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("저장 처리 중 오류가 발생했습니다.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingStore = false);
    }
  }

  Future<_StoreFetchResult?> _fetchStoreFromSupabase(NaverPlace place, NLatLng position) async {
    await _ensureResolvedIdentity(place, position);

    final name = _effectiveStoreName(place);

    // ✅ [문제 1 해결] 점수 불일치 해결을 위해 매장 이름으로 전체 검색 (주소 무관)
    // RankingScreen과 로직을 통일하여 해당 이름의 모든 리뷰를 긁어옴
    List rows = [];
    try {
      final res = await _supabase
          .from('reviews')
          .select('needsfine_score, trust_level, photo_urls, is_hidden, tags')
          .eq('store_name', name);
      rows = (res is List) ? res : [];
    } catch (e) {
      debugPrint("리뷰 전체 조회 실패: $e");
    }

    if (rows.isEmpty) return null;

    double totalScore = 0.0;
    int totalTrust = 0;
    int count = 0;
    final photos = <String>{};
    final tagCounts = <String, int>{}; // 태그 집계용

    for (final r in rows) {
      final m = r as Map;
      final hidden = m['is_hidden'];
      if (hidden is bool && hidden == true) continue;

      final s = m['needsfine_score'];
      final t = m['trust_level'];

      totalScore += (s is num) ? s.toDouble() : 0.0;
      totalTrust += (t is num) ? t.round() : 0;
      count++;

      final pu = m['photo_urls'];
      if (pu is List) {
        for (final x in pu) { if (x is String && x.isNotEmpty) photos.add(x); }
      }

      // ✅ [문제 1 해결] 태그 집계 (배열 파싱)
      final tags = m['tags'];
      if (tags is List) {
        for (final tag in tags) {
          final tStr = tag.toString();
          if (tStr.isNotEmpty) tagCounts[tStr] = (tagCounts[tStr] ?? 0) + 1;
        }
      }
    }

    if (count == 0) return null;

    final avgScore = totalScore / count;
    final avgTrust = (totalTrust / count).round();

    // 상위 태그 3개 추출
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(3).map((e) => e.key).toList();

    // Store 객체 생성 (호환용)
    final store = _createStoreFlexible(
      name: name,
      latitude: position.latitude,
      longitude: position.longitude,
      needsFineScore: avgScore,
      avgTrust: avgTrust,
      reviewCount: count,
      allPhotos: photos.toList(),
      address: _effectiveStoreAddress(place),
    );

    return _StoreFetchResult(
      store: store,
      storeName: name,
      storeAddress: _effectiveStoreAddress(place),
      avgScore: avgScore, // ✅ 계산된 점수 전달
      avgTrust: avgTrust, // ✅ 계산된 신뢰도 전달
      topTags: topTags,   // ✅ 계산된 태그 전달
    );
  }

  void _updateUI(NaverPlace place, NLatLng position) async {
    // 1. 상태 초기화
    _resetStoreState();

    Store? matched;
    try {
      matched = AppData().stores.firstWhere(
            (s) => s.name == place.cleanTitle || (s.latitude - position.latitude).abs() < 0.0005,
      );
    } catch (_) {
      matched = null;
    }

    final initialAddr = _normalizedAddress(place);
    if (mounted) {
      setState(() {
        _searchedPlace = place;
        _matchedStore = matched;
        _selectedPosition = position;
        _showBottomSheet = true;

        if (place.cleanTitle.trim().isNotEmpty) _resolvedStoreName ??= place.cleanTitle.trim();
        if (initialAddr.trim().isNotEmpty) _resolvedStoreAddress ??= initialAddr.trim();
      });
    }

    await _loadStoreCountsAndState(place, position);

    // 2. Supabase 데이터 조회 및 점수 업데이트
    final dbResult = await _fetchStoreFromSupabase(place, position);

    if (mounted) {
      if (dbResult != null) {
        setState(() {
          _matchedStore = dbResult.store;
          if (dbResult.storeName != null && dbResult.storeName!.trim().isNotEmpty) {
            _resolvedStoreName = dbResult.storeName!.trim();
          }
          if (dbResult.storeAddress != null && dbResult.storeAddress!.trim().isNotEmpty) {
            _resolvedStoreAddress = dbResult.storeAddress!.trim();
          }

          // ✅ [핵심] DB에서 계산된 점수, 신뢰도, 태그를 화면 상태 변수에 반영
          _displayScore = dbResult.avgScore;
          _displayTrust = dbResult.avgTrust;
          _displayTags = dbResult.topTags;
        });
      } else {
        // 데이터가 없으면 초기값 유지
      }
    }

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
          initialStoreName: _resolvedStoreName ?? _searchedPlace?.cleanTitle,
          initialAddress: (_resolvedStoreAddress != null && _resolvedStoreAddress!.trim().isNotEmpty)
              ? _resolvedStoreAddress
              : (_searchedPlace?.roadAddress.isNotEmpty == true
              ? _searchedPlace!.roadAddress
              : _searchedPlace?.address),
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 지도
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: _initialPosition,
              locationButtonEnable: true,
              indoorEnable: true,
            ),
            onMapReady: (controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            onCameraChange: _onCameraChange,
            onMapTapped: (_, __) {
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.searchStoreHint,
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF9C7CFF)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (val) => _handleManualSearch(val),
                      ),
                    ),

                    if (_autocompleteResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 250),
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
                                _selectPlace(place);
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
                          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
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
    // ✅ l10n 객체 가져오기
    final l10n = AppLocalizations.of(context)!;

    final place = _searchedPlace!;
    final store = _matchedStore;

    final title = _effectiveStoreName(place);
    final addrText = _displayAddress(place);

    // 리뷰 개수 및 사진은 Store 객체에서 가져옴 (없으면 0)
    int reviewCount = 0;
    List<String> photos = [];

    if (store != null) {
      reviewCount = _getStoreReviewCount(store);
      photos = _getStorePhotos(store);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 매장 이름 및 저장 버튼
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _toggleStoreSave,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isStoreSaved ? const Color(0xFF9C7CFF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF9C7CFF)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isStoreSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 18,
                        color: _isStoreSaved ? Colors.white : const Color(0xFF9C7CFF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isStoreSaved ? l10n.saved : l10n.save,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isStoreSaved ? Colors.white : const Color(0xFF9C7CFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          if (addrText.isNotEmpty)
            Text(addrText, style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(height: 16),

          // ✅ 점수/신뢰도 표시 (Store 객체가 있으면 보여줌)
          if (store != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 니즈파인 점수 (상태 변수 사용)
                _buildScoreBox(
                    l10n.avgNeedsFineScore, // NeedsFine Score
                    _displayScore.toStringAsFixed(1),
                    const Color(0xFF9C7CFF)
                ),

                // 평균 신뢰도 (상태 변수 사용)
                _buildScoreBox(
                  l10n.avgReliability,
                  "$_displayTrust%",
                  _displayTrust >= 50 ? const Color(0xFF9C7CFF) : Colors.orange,
                ),
              ],
            ),

            // ✅ [문제 1 해결] 태그 표시
            if (_displayTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _displayTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E9FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "#$tag",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C4DFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),
            Text("${l10n.review} $reviewCount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StoreReviewsScreen(store: store)),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("$_storeCommentCount", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                InkWell(
                  onTap: _toggleStoreSave,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _isStoreSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 18,
                          color: const Color(0xFF9C7CFF),
                        ),
                        const SizedBox(width: 6),
                        Text("$_storeSaveCount", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C7CFF))),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ✅ [추가] 매장 정보 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreInfoScreen(
                        storeName: title,
                        storeAddress: addrText,
                        lat: _selectedPosition?.latitude ?? 0,
                        lng: _selectedPosition?.longitude ?? 0,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.store, color: Color(0xFF9C7CFF)),
                label: const Text('매장 정보', style: TextStyle(color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF9C7CFF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (photos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photos[index],
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
                child: Center(child: Text(l10n.noPhotos, style: const TextStyle(color: Colors.grey))),
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
                    child: Text(l10n.viewReview, style: const TextStyle(color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
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
                    child: Text(l10n.writeReview, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  Text(l10n.noStoreInfo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l10n.shareExperience, style: const TextStyle(color: Color(0xFF9C7CFF))),
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
              child: Text(l10n.writeFirstReview, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],

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

// ✅ StoreFetchResult 수정 (점수/신뢰도/태그 추가 반환)
class _StoreFetchResult {
  final Store store;
  final String? storeName;
  final String? storeAddress;
  final double avgScore;
  final int avgTrust;
  final List<String> topTags; // ✅ 태그 추가

  const _StoreFetchResult({
    required this.store,
    this.storeName,
    this.storeAddress,
    this.avgScore = 0.0,
    this.avgTrust = 0,
    this.topTags = const [], // ✅ 기본값 설정
  });
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