import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/screens/weekly_ranking_screen.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';

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
  bool _isLoading = true;

  // 데이터 상태 변수
  List<StoreRanking> _top100 = [];
  final Map<String, String> _storeImageMap = {};
  List<Map<String, dynamic>> _bestReviews = [];

  List<String> _bannerList = [];
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  // 디자인 토큰
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
    _loadHomeData();
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

  Future<void> _loadHomeData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // 1. 배너 로드
      final bannerData = await _supabase
          .from('banners')
          .select('image_url')
          .order('created_at', ascending: true);

      final List<String> loadedBanners = [];
      for (var row in bannerData) {
        loadedBanners.add(row['image_url'] as String);
      }

      // 2. 주간 랭킹 로드
      final rankings = await ReviewService.fetchStoreRankings();
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

      final names = top100.map((e) => e.storeName).where((e) => e.isNotEmpty).toSet().toList();

      // 공식 이미지 + 리뷰 이미지 하이브리드 로딩
      final imageMap = await _fetchStoreImagesWithReviews(names);

      // 3. 베스트 리뷰 로드
      final bestReviewsData = await _supabase
          .from('reviews')
          .select('''
            *, 
            profiles(nickname, profile_image_url),
            review_votes(count), 
            comments(count)
          ''')
          .not('photo_urls', 'is', null)
          .order('needsfine_score', ascending: false)
          .limit(5);

      List<Map<String, dynamic>> finalBestReviews = List<Map<String, dynamic>>.from(bestReviewsData);

      if (finalBestReviews.isEmpty) {
        finalBestReviews = [
          {
            'id': 'dummy1',
            'store_name': '스시 오마카세 청담',
            'review_text': '쉐프님의 접객이 정말 훌륭했습니다.',
            'needsfine_score': 4.8,
            'user_rating': 5.0,
            'photo_urls': [],
            'tags': ['데이트', '기념일'],
            'created_at': DateTime.now().toIso8601String(),
            'user_id': 'dummy_user',
            'review_votes': [{'count': 124}],
            'comments': [{'count': 18}],
            'profiles': {'nickname': '미식가라이언', 'profile_image_url': null}
          },
        ];
      }

      if (mounted) {
        setState(() {
          _bannerList = loadedBanners;
          _top100 = top100;
          _storeImageMap..clear()..addAll(imageMap);
          _bestReviews = finalBestReviews;
        });
      }
    } catch (e) {
      debugPrint("홈 데이터 로드 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> _fetchStoreImagesWithReviews(List<String> storeNames) async {
    if (storeNames.isEmpty) return {};
    final map = <String, String>{};
    final List<String> missingImages = [];

    try {
      final res = await _supabase.from('stores').select('name, image_url').inFilter('name', storeNames);

      if (res is List) {
        for (final row in res) {
          final name = (row['name'] ?? '').toString();
          final url = (row['image_url'] ?? '').toString();
          if (name.isNotEmpty && url.isNotEmpty) {
            map[name] = url;
          }
        }
      }

      for (var name in storeNames) {
        if (!map.containsKey(name)) {
          missingImages.add(name);
        }
      }

      if (missingImages.isNotEmpty) {
        final reviewRes = await _supabase
            .from('reviews')
            .select('store_name, photo_urls')
            .inFilter('store_name', missingImages)
            .not('photo_urls', 'is', null)
            .order('created_at', ascending: false);

        if (reviewRes is List) {
          for (final row in reviewRes) {
            final name = (row['store_name'] ?? '').toString();
            if (map.containsKey(name)) continue;
            final List photos = row['photo_urls'] ?? [];
            if (photos.isNotEmpty) {
              map[name] = photos[0].toString();
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
    searchTrigger.value = SearchTarget(query: query);
    FocusScope.of(context).unfocus();
  }

  void _goToWeeklyMore() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyRankingScreen(rankings: _top100, storeImageMap: _storeImageMap)));
  }

  void _goToReviewDetail(Map<String, dynamic> reviewMap) async {
    try {
      final reviewObj = Review.fromJson(reviewMap);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewDetailScreen(review: reviewObj),
        ),
      );

      _loadHomeData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("리뷰 정보를 불러오는데 실패했습니다.")),
      );
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
        onRefresh: _loadHomeData,
        child: _isLoading
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
                  children: const [
                    Text("실시간 베스트 리뷰 🏆", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    Spacer(),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
            hintText: '맛집, 지역, 키워드 검색',
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
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("등록된 이미지가 없습니다.", style: TextStyle(color: Colors.grey)),
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
          final double trustScore = (review['trust_score'] as num?)?.toDouble() ?? 98.0;

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
                    // (왼쪽) 1위 BEST
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
                    // (오른쪽) 니즈파인 점수 + 신뢰도
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Row(
                        children: [
                          // 1. 니즈파인 점수
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5).withOpacity(0.95), // 연한 니즈파인색
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
                          // 2. 신뢰도
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD).withOpacity(0.95), // 연한 파란색
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
          final imageUrl = _storeImageMap[r.storeName] ?? '';
          return _WeeklyRankCard(
            ranking: r,
            imageUrl: imageUrl,
            onTap: () {
              if (r.storeName.isNotEmpty) searchTrigger.value = SearchTarget(query: r.storeName);
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
                        decoration: BoxDecoration(color: const Color(0xFFF3E5F5)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_rounded, size: 48, color: _brand.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text("이미지 준비중", style: TextStyle(color: _brand.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
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
                          '${ranking.rank}위',
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
            // ✅ [수정] 둘 다 Expanded로 감싸서 1:1 비율 적용
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  // 1. 니즈파인 점수 (Expanded 추가)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _brand.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "니즈파인 ${ranking.avgScore.toStringAsFixed(1)}",
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
                  // 2. 신뢰도 (Expanded 유지)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%',
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