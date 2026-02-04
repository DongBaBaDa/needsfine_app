import 'dart:async';
import 'dart:io'; // SocketException 처리를 위해 필요
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/screens/weekly_ranking_screen.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';

class StoreMetadata {
  final String? imageUrl;
  final double? lat;
  final double? lng;

  StoreMetadata({this.imageUrl, this.lat, this.lng});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  // 초기 로딩 상태
  bool _isInitialLoading = true;

  List<StoreRanking> _top100 = [];
  final Map<String, StoreMetadata> _storeMetadataMap = {};
  List<Map<String, dynamic>> _bestReviews = [];
  List<String> _bannerList = [];

  // 배너 관련
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  static const Color _brand = Color(0xFF8A2BE2);
  static const Color _bg = Color(0xFFF2F2F7);
  static const Color _card = Colors.white;

  static final List<BoxShadow> _softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeDataProgressive();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients && _bannerList.isNotEmpty) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= _bannerList.length) nextPage = 0;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // 🔄 [네트워크 재시도 로직]
  Future<T> _retryRequest<T>(Future<T> Function() request, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await request();
      } catch (e) {
        if (e is SocketException || e.toString().contains('SocketException')) {
          if (i == retries - 1) rethrow; // 마지막 시도도 실패하면 에러 던짐

          // ⚡ [수정 완료] const 키워드 제거 (변수 i가 포함되어 있어서 const 불가능)
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));

          debugPrint("🔄 네트워크 재연결 시도 중... (${i + 1}/$retries)");
        } else {
          rethrow;
        }
      }
    }
    throw Exception("네트워크 연결 실패");
  }

  // 🚀 [핵심] 프로그레시브 로딩
  Future<void> _loadHomeDataProgressive() async {
    if (_top100.isEmpty && mounted) setState(() => _isInitialLoading = true);

    try {
      // 1단계: 필수 데이터
      final results = await Future.wait<dynamic>([
        _retryRequest(() => _supabase.from('banners').select('image_url').order('created_at', ascending: true)),
        _retryRequest(() => ReviewService.fetchStoreRankings()),
        _retryRequest(() => _supabase.from('reviews').select('*, profiles(nickname, profile_image_url), review_votes(count), comments(count)').not('photo_urls', 'is', null).order('needsfine_score', ascending: false).limit(5)),
      ]);

      final bannerData = results[0] as List<dynamic>;
      final rankings = results[1] as List<StoreRanking>;
      final bestReviewsData = results[2] as List<dynamic>;

      // 랭킹 정렬
      final sorted = List<StoreRanking>.from(rankings);
      sorted.sort((a, b) => b.avgScore.compareTo(a.avgScore));

      final top100 = sorted.take(100).toList();
      for (int i = 0; i < top100.length; i++) {
        top100[i] = StoreRanking(
          storeName: top100[i].storeName,
          avgScore: top100[i].avgScore,
          avgUserRating: top100[i].avgUserRating,
          reviewCount: top100[i].reviewCount,
          avgTrust: top100[i].avgTrust,
          rank: i + 1,
          topTags: top100[i].topTags,
        );
      }

      // 🔥 [1차 UI 갱신]
      if (mounted) {
        setState(() {
          _bannerList = bannerData.map((e) => e['image_url'] as String).toList();
          _top100 = top100;
          _bestReviews = List<Map<String, dynamic>>.from(bestReviewsData);
          _isInitialLoading = false;
        });
      }

      // 2단계: 무거운 데이터 (좌표, 이미지) 백그라운드 로딩
      final names = top100.map((e) => e.storeName).where((e) => e.isNotEmpty).toSet().toList();
      final metaMap = await _fetchStoreMetadata(names);

      // 🔥 [2차 UI 갱신]
      if (mounted) {
        setState(() {
          _storeMetadataMap..clear()..addAll(metaMap);
        });
      }

    } catch (e) {
      debugPrint("홈 데이터 로드 실패: $e");
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<Map<String, StoreMetadata>> _fetchStoreMetadata(List<String> storeNames) async {
    if (storeNames.isEmpty) return {};
    final map = <String, StoreMetadata>{};
    final List<String> missingStores = [];

    try {
      // 좌표 쿼리도 재시도 로직 적용
      final res = await _retryRequest(() => _supabase
          .from('stores')
          .select('name, image_url, lat, lng')
          .inFilter('name', storeNames));

      if (res is List) {
        for (final row in res) {
          final name = (row['name'] ?? '').toString();
          final url = (row['image_url'] ?? '').toString();
          final lat = (row['lat'] as num?)?.toDouble();
          final lng = (row['lng'] as num?)?.toDouble();
          if (name.isNotEmpty) {
            map[name] = StoreMetadata(imageUrl: url, lat: lat, lng: lng);
          }
        }
      }

      for (var name in storeNames) {
        if (!map.containsKey(name)) missingStores.add(name);
      }

      if (missingStores.isNotEmpty) {
        final reviewRes = await _supabase
            .from('reviews')
            .select('store_name, photo_urls')
            .inFilter('store_name', missingStores)
            .not('photo_urls', 'is', null)
            .order('created_at', ascending: false);

        if (reviewRes is List) {
          for (final row in reviewRes) {
            final name = (row['store_name'] ?? '').toString();
            if (map.containsKey(name)) continue;
            final List photos = row['photo_urls'] ?? [];
            if (photos.isNotEmpty) {
              map[name] = StoreMetadata(imageUrl: photos[0].toString(), lat: null, lng: null);
            }
          }
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  void _submitSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) return;

    Future.microtask(() {
      searchTrigger.value = SearchTarget(query: query);
    });
    FocusScope.of(context).unfocus();
  }

  void _goToWeeklyMore() {
    final imageMap = _storeMetadataMap.map((key, value) => MapEntry(key, value.imageUrl ?? ''));
    Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyRankingScreen(rankings: _top100, storeImageMap: imageMap)));
  }

  void _goToReviewDetail(Map<String, dynamic> reviewMap) async {
    try {
      final reviewObj = Review.fromJson(reviewMap);
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: reviewObj)));
    } catch (e) {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'NeedsFine',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 24),
        ),
        actions: [
          NotificationBadge(onTap: () => Navigator.pushNamed(context, '/notifications')),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        color: _brand,
        onRefresh: _loadHomeDataProgressive,
        child: _isInitialLoading
            ? const Center(child: CircularProgressIndicator(color: _brand))
            : ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildAdBanner(),
            const SizedBox(height: 24),

            if (_bestReviews.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(l10n.realTimeBestReviews, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildBestReviews(),
              const SizedBox(height: 32),
            ],

            _sectionTitle(
              l10n.weeklyRanking,
              trailing: TextButton(
                onPressed: _goToWeeklyMore,
                style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                child: Text(
                  l10n.more,
                  style: const TextStyle(color: _brand, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _buildWeeklyHorizontal(l10n),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _softShadow,
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchPlaceholder,
            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600),
            prefixIcon: const Icon(Icons.search_rounded, color: _brand),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black54),
              onPressed: () => _submitSearch(_searchController.text),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    final l10n = AppLocalizations.of(context)!;
    bool isEmpty = _bannerList.isEmpty;
    int totalCount = isEmpty ? 0 : _bannerList.length;
    int displayIndex = isEmpty ? 0 : (_currentBannerIndex + 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 2.4,
        child: Stack(
          children: [
            if (isEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(l10n.noImages, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              PageView.builder(
                controller: _bannerController,
                itemCount: _bannerList.length,
                onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _bannerList[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.error, color: Colors.red)),
                      ),
                    ),
                  );
                },
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$displayIndex / $totalCount",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestReviews() {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _bestReviews.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final review = _bestReviews[index];
          final List photoUrls = review['photo_urls'] ?? [];
          final String mainImage = photoUrls.isNotEmpty ? photoUrls[0] : '';
          final double score = (review['needsfine_score'] as num?)?.toDouble() ?? 0.0;
          final String storeName = review['store_name'] ?? '알 수 없는 가게';
          final String content = review['review_text'] ?? '';
          final double trustScore = (review['trust_level'] as num?)?.toDouble() ?? 50.0;

          int getCount(dynamic key) {
            final val = review[key];
            if (val is List && val.isNotEmpty) {
              return (val[0]['count'] as num?)?.toInt() ?? 0;
            }
            if (val is int) return val;
            return 0;
          }

          final int likes = getCount('review_votes');
          final int comments = getCount('comments');

          return GestureDetector(
            onTap: () => _goToReviewDetail(review),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(color: _brand.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mainImage.isNotEmpty)
                      Image.network(
                        mainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [const Color(0xFF2C2C3E), const Color(0xFF1F1F2E)],
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _brand,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          "${index + 1}위 BEST",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "니즈파인 ${score.toStringAsFixed(1)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: _brand,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "신뢰도 ${trustScore.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(storeName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(content, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.thumb_up_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text("$likes", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text("$comments", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyHorizontal(AppLocalizations l10n) {
    if (_top100.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(l10n.noInfo, style: const TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 292,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _top100.take(5).length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final r = _top100[index];
          final meta = _storeMetadataMap[r.storeName];
          final imageUrl = meta?.imageUrl ?? '';

          return _WeeklyRankCard(
            ranking: r,
            imageUrl: imageUrl,
            onTap: () {
              if (r.storeName.isNotEmpty) {
                // 클릭 시점에 메타데이터(좌표)가 있으면 바로 이동
                Future.microtask(() {
                  searchTrigger.value = SearchTarget(
                    query: r.storeName,
                    lat: meta?.lat,
                    lng: meta?.lng,
                  );
                });
              }
            },
            l10n: l10n,
          );
        },
      ),
    );
  }
}

class _WeeklyRankCard extends StatelessWidget {
  static const Color _brand = Color(0xFF8A2BE2);

  final StoreRanking ranking;
  final String imageUrl;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _WeeklyRankCard({
    required this.ranking,
    required this.imageUrl,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                    else
                      Container(
                        decoration: const BoxDecoration(color: Color(0xFFF3E5F5)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_rounded, size: 48, color: _brand.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text(l10n.imagePreparing, style: TextStyle(color: _brand.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.35)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                        ),
                        child: Text(
                          '${ranking.rank}${l10n.rank}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Text(
                        ranking.storeName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, height: 1.1, shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _brand.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                          "${l10n.needsFine} ${ranking.avgScore.toStringAsFixed(1)}",
                        style: const TextStyle(
                          color: _brand,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${l10n.trustScore} ${ranking.avgTrust.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}