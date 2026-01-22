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

// ✅ Supabase 조회
import 'package:supabase_flutter/supabase_flutter.dart';

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
    target: NLatLng(37.5665, 126.9780), // 기본 위치 (서울시청)
    zoom: 14.0,
  );

  // ✅ Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ 매장 저장 상태/카운트, 댓글 카운트
  bool _isStoreSaved = false;
  bool _isSavingStore = false;
  int _storeSaveCount = 0;
  int _storeCommentCount = 0;

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

  // ✅ 외부 요청 처리 로직 (DB 좌표 복구 기능 포함)
  void _handleExternalSearch() async {
    final target = searchTrigger.value;
    if (target != null) {
      _searchController.text = target.query;
      searchTrigger.value = null; // 트리거 초기화
      FocusScope.of(context).unfocus();

      if (mounted) {
        setState(() {
          _autocompleteResults = [];
          // 🔴 상태 초기화 (이전 매장 정보 삭제)
          _resolvedStoreName = null;
          _resolvedStoreAddress = null;
          _matchedStore = null;
          _isStoreSaved = false;
          _storeSaveCount = 0;
          _storeCommentCount = 0;
        });
      }

      // 1) 좌표가 명확한 경우 -> 즉시 이동
      if (target.lat != null && target.lng != null && target.lat != 0 && target.lng != 0) {
        _moveToCoordinates(target.query, target.lat!, target.lng!);
      }
      // 2) 좌표가 없는 경우 -> DB에서 좌표 찾기 시도 (Smart Fallback)
      else {
        final dbCoords = await _findCoordinatesFromDB(target.query);
        if (dbCoords != null) {
          // DB에 좌표가 있으면 그걸로 이동
          _moveToCoordinates(target.query, dbCoords.latitude, dbCoords.longitude);
        } else {
          // DB에도 없으면 네이버 검색 실행
          _handleManualSearch(target.query);
        }
      }
    }
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
      _resolvedStoreName = null;
      _resolvedStoreAddress = null;
      _matchedStore = null;
      _isStoreSaved = false;
      _storeSaveCount = 0;
      _storeCommentCount = 0;
    });

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

  Widget _buildCustomMarkerWidget(String title) {
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
                title,
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
    setState(() {
      _searchController.text = place.cleanTitle;
      _autocompleteResults = [];
      // 🔴 새로운 장소 선택 시 상태 초기화
      _resolvedStoreName = null;
      _resolvedStoreAddress = null;
      _matchedStore = null;
      _isStoreSaved = false;
      _storeSaveCount = 0;
      _storeCommentCount = 0;
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("정확한 좌표를 찾을 수 없습니다.")));
      }
    } catch (e) {
      debugPrint("Select Place Error: $e");
    }
  }

  // ✅ Store 생성자
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

  double _getStoreScore(Store s) {
    final d = s as dynamic;
    try { return (d.needsFineScore as num).toDouble(); } catch (_) { return 0.0; }
  }

  int _getStoreTrust(Store s) {
    return 0;
  }

  int _getStoreReviewCount(Store s) {
    final d = s as dynamic;
    try { return (d.reviewCount as num).toInt(); } catch (_) { return 0; }
  }

  List<String> _getStorePhotos(Store s) {
    return [];
  }

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

      if (addr.isNotEmpty) {
        final filtered = list.where((r) {
          final m = r as Map;
          return ((m['store_address'] ?? '').toString().trim() == addr);
        }).toList();
        if (filtered.isNotEmpty) list = filtered;
      }

      if (list.isEmpty) {
        final eps = 0.002;
        final rows2 = await _supabase
            .from('reviews')
            .select('comment_count, is_hidden, store_lat, store_lng')
            .gte('store_lat', position.latitude - eps)
            .lte('store_lat', position.latitude + eps)
            .gte('store_lng', position.longitude - eps)
            .lte('store_lng', position.longitude + eps);

        list = (rows2 is List) ? rows2 : [];
      }

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
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
          const SnackBar(content: Text("주소를 확인 중입니다. 잠시 후 다시 시도해주세요.")),
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
    final addr = _effectiveStoreAddress(place);

    List rows = [];
    String? foundName;
    String? foundAddr;

    if (addr.isNotEmpty) {
      try {
        final res = await _supabase
            .from('reviews')
            .select('needsfine_score, trust_level, photo_urls, is_hidden, store_lat, store_lng, store_name, store_address')
            .eq('store_name', name)
            .eq('store_address', addr);
        rows = (res is List) ? res : [];
        if (rows.isNotEmpty) { foundName = name; foundAddr = addr; }
      } catch (e) { debugPrint("reviews(name+addr) 조회 실패: $e"); }
    }

    if (rows.isEmpty) {
      try {
        final res = await _supabase
            .from('reviews')
            .select('needsfine_score, trust_level, photo_urls, is_hidden, store_lat, store_lng, store_name, store_address')
            .eq('store_name', name);
        rows = (res is List) ? res : [];
        if (rows.isNotEmpty) {
          foundName = name;
          final addrCount = <String, int>{};
          for (final r in rows) {
            final m = r as Map;
            final a = (m['store_address'] ?? '').toString().trim();
            if (a.isNotEmpty) addrCount[a] = (addrCount[a] ?? 0) + 1;
          }
          String? best; int bestN = -1;
          addrCount.forEach((k, v) { if (v > bestN) { bestN = v; best = k; } });
          if (best != null && best!.isNotEmpty) foundAddr = best;
        }
      } catch (e) { debugPrint("reviews(name only) 조회 실패: $e"); }
    }

    if (rows.isEmpty) {
      try {
        final eps = 0.002;
        final res2 = await _supabase
            .from('reviews')
            .select('needsfine_score, trust_level, photo_urls, is_hidden, store_lat, store_lng, store_name, store_address')
            .gte('store_lat', position.latitude - eps)
            .lte('store_lat', position.latitude + eps)
            .gte('store_lng', position.longitude - eps)
            .lte('store_lng', position.longitude + eps);
        rows = (res2 is List) ? res2 : [];
        if (rows.isNotEmpty) {
          final nameCount = <String, int>{};
          final addrCount = <String, int>{};
          for (final r in rows) {
            final m = r as Map;
            final sn = (m['store_name'] ?? '').toString().trim();
            final sa = (m['store_address'] ?? '').toString().trim();
            if (sn.isNotEmpty) nameCount[sn] = (nameCount[sn] ?? 0) + 1;
            if (sa.isNotEmpty) addrCount[sa] = (addrCount[sa] ?? 0) + 1;
          }
          String? bestName; int bn = -1;
          nameCount.forEach((k, v) { if (v > bn) { bn = v; bestName = k; } });
          String? bestAddr; int ba = -1;
          addrCount.forEach((k, v) { if (v > ba) { ba = v; bestAddr = k; } });
          if (bestName != null && bestName!.isNotEmpty) foundName = bestName;
          if (bestAddr != null && bestAddr!.isNotEmpty) foundAddr = bestAddr;
          if (mounted) {
            setState(() {
              if (foundName != null && foundName!.isNotEmpty) _resolvedStoreName = foundName;
              if (foundAddr != null && foundAddr!.isNotEmpty) _resolvedStoreAddress = foundAddr;
            });
          }
        }
      } catch (e) { debugPrint("reviews(lat/lng) 조회 실패: $e"); }
    }

    if (rows.isEmpty) return null;

    double totalScore = 0.0;
    int totalTrust = 0;
    int count = 0;
    final photos = <String>{};

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
    }

    if (count == 0) return null;

    final avgScore = totalScore / count;
    final avgTrust = (totalTrust / count).round();

    final store = _createStoreFlexible(
      name: foundName ?? name,
      latitude: position.latitude,
      longitude: position.longitude,
      needsFineScore: avgScore,
      avgTrust: avgTrust,
      reviewCount: count,
      allPhotos: photos.toList(),
      address: foundAddr ?? addr,
    );

    return _StoreFetchResult(
      store: store,
      storeName: foundName ?? name,
      storeAddress: foundAddr,
    );
  }

  void _updateUI(NaverPlace place, NLatLng position) async {
    // 🔴 [핵심] 이전 검색 정보 완전 초기화
    setState(() {
      _resolvedStoreName = null;
      _resolvedStoreAddress = null;
      _matchedStore = null;
      _isStoreSaved = false;
      _storeSaveCount = 0;
      _storeCommentCount = 0;
    });

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

    final db = await _fetchStoreFromSupabase(place, position);
    if (db != null && mounted) {
      setState(() {
        _matchedStore = db.store;
        if (db.storeName != null && db.storeName!.trim().isNotEmpty) _resolvedStoreName = db.storeName!.trim();
        if (db.storeAddress != null && db.storeAddress!.trim().isNotEmpty) _resolvedStoreAddress = db.storeAddress!.trim();
      });
      await _loadStoreCountsAndState(place, position);
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
                        decoration: const InputDecoration(
                          hintText: '매장 검색',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF9C7CFF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    final place = _searchedPlace!;
    final store = _matchedStore;

    final title = _effectiveStoreName(place);
    final addrText = _displayAddress(place);

    // 미리 변수 계산 (컴파일 에러 방지)
    double score = 0.0;
    int trust = 0;
    int reviewCount = 0;
    List<String> photos = [];

    if (store != null) {
      score = _getStoreScore(store);
      trust = _getStoreTrust(store);
      reviewCount = _getStoreReviewCount(store);
      photos = _getStorePhotos(store);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        _isStoreSaved ? "저장됨" : "저장하기",
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

          // ✅ [수정됨] 매장 이름 바로 아래 회색 주소 (요청사항 반영)
          const SizedBox(height: 4),
          if (addrText.isNotEmpty)
            Text(addrText, style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(height: 16),

          if (store != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildScoreBox("니즈파인 점수", score.toStringAsFixed(1), const Color(0xFF9C7CFF)),
                _buildScoreBox(
                  "평균 신뢰도",
                  "$trust%",
                  trust >= 50 ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text("리뷰 $reviewCount개", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class _StoreFetchResult {
  final Store store;
  final String? storeName;
  final String? storeAddress;
  const _StoreFetchResult({required this.store, this.storeName, this.storeAddress});
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