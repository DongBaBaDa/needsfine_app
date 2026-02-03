import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/screens/weekly_ranking_screen.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';
import 'package:needsfine_app/data/korean_regions.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart'; // ✅ 실제 파일 import

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
  List<Map<String, dynamic>> _bestReviews = []; // 🔥 베스트 리뷰 데이터

  List<String> _bannerList = [];
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  String? _selectedProvince;

  // 에러 방지용 변수 (화면엔 안 나오지만 빌드 에러 방지)
  final Map<String, List<String>> _tagCategories = {
    '혼자서 👤': ['혼밥', '힐링', '가성비', '브런치', '포장가능', '조용한', '간편한'],
    '둘이서 👩‍❤️‍👨': ['데이트', '기념일', '분위기맛집', '뷰맛집', '이색요리', '와인', '코스요리'],
    '여럿이 👨‍👩‍👧‍👦': ['회식', '가족모임', '친구모임', '주차가능', '룸있음', '대화하기좋은', '넓은좌석'],
  };
  String _currentTagTab = '혼자서 👤';

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

      // 3. 🔥 베스트 리뷰 로드 (사진 있고, 점수 높은 순 5개)
      final bestReviewsData = await _supabase
          .from('reviews')
          .select()
          .not('photo_urls', 'is', null) // 사진이 있는 것만
          .order('needsfine_score', ascending: false) // 점수 높은 순
          .limit(5);

      // [테스트용 강제 주입]
      List<Map<String, dynamic>> finalBestReviews = List<Map<String, dynamic>>.from(bestReviewsData);

      if (finalBestReviews.isEmpty) {
        finalBestReviews = [
          {
            'id': 'dummy1',
            'store_name': '스시 오마카세 청담',
            'review_text': '쉐프님의 접객이 정말 훌륭했습니다. 특히 우니가 신선해서 입에서 녹네요. 가격대는 좀 있지만 특별한 날 오기에 부족함이 없습니다.',
            'needsfine_score': 4.8,
            'user_rating': 5.0,
            'photo_urls': [],
            'tags': ['데이트', '기념일'],
            'created_at': DateTime.now().toIso8601String(),
            'user_id': 'dummy_user',
            'likes_count': 124,
            'comment_count': 18,
          },
          {
            'id': 'dummy2',
            'store_name': '연남동 파스타',
            'review_text': '분위기가 너무 좋아서 데이트 코스로 딱이에요! 재방문 의사 100%입니다.',
            'needsfine_score': 4.5,
            'user_rating': 4.5,
            'photo_urls': [],
            'tags': ['파스타', '분위기'],
            'created_at': DateTime.now().toIso8601String(),
            'user_id': 'dummy_user',
            'likes_count': 89,
            'comment_count': 5,
          },
          {
            'id': 'dummy3',
            'store_name': '성수 베이글',
            'review_text': '주말에는 웨이팅이 좀 있지만 기다릴 가치가 있습니다. 런던 베이글보다 맛있어요.',
            'needsfine_score': 4.2,
            'user_rating': 4.0,
            'photo_urls': [],
            'tags': ['베이글', '맛집'],
            'created_at': DateTime.now().toIso8601String(),
            'user_id': 'dummy_user',
            'likes_count': 230,
            'comment_count': 42,
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

  // 가게 이미지 + 리뷰 이미지 통합 로드
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
      debugPrint("이미지 로드 중 오류: $e");
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

  void _searchByRegion(String regionName) {
    searchTrigger.value = SearchTarget(query: regionName);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$regionName(으)로 검색합니다.")));
  }

  // ✅ [수정] Map 데이터를 Review 모델로 변환하여 이동
  void _goToReviewDetail(Map<String, dynamic> reviewMap) {
    try {
      // Map을 Review 모델로 변환 (fromJson 사용)
      final reviewObj = Review.fromJson(reviewMap);

      Navigator.push(
        context,
        MaterialPageRoute(
          // ✅ 수정 포인트: 이제 여기서 review: 파라미터를 사용합니다.
          // (ReviewDetailScreen.dart를 수정하셔야 이 코드가 정상 작동합니다)
          builder: (_) => ReviewDetailScreen(review: reviewObj),
        ),
      );
    } catch (e) {
      debugPrint("리뷰 변환 오류: $e");
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

            // ✅ 2. 실시간 베스트 리뷰 섹션
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
              _buildBestReviews(), // 클릭 기능 및 좋아요/댓글 UI 추가됨
              const SizedBox(height: 32),
            ],

            // 5. 주간 랭킹
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

  // --- 위젯 빌더 메서드들 ---

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
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
                onPageChanged: (index) {
                  setState(() => _currentBannerIndex = index);
                },
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
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

  // ✅ [수정됨] GestureDetector 추가 (클릭 이동)
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

          // 좋아요, 댓글 수 가져오기 (없으면 0)
          final int likes = review['likes_count'] ?? 0;
          final int comments = review['comment_count'] ?? 0;

          return GestureDetector(
            onTap: () => _goToReviewDetail(review), // 클릭 시 상세 화면 이동
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
                    // 1. 배경 이미지
                    if (mainImage.isNotEmpty)
                      Image.network(
                        mainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
                      )
                    else
                    // 이미지가 없을 때 대체 디자인
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [const Color(0xFF2C2C3E), const Color(0xFF1F1F2E)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.white.withOpacity(0.3)),
                              const SizedBox(height: 8),
                              Text(
                                "이미지 준비중",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 2. 그라데이션 오버레이 (밝기 수정: 0.6)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1), // 상단은 투명하게
                            Colors.transparent,
                            Colors.black.withOpacity(0.7), // 하단 텍스트 부분은 적당히 어둡게
                          ],
                          stops: const [0.0, 0.4, 1.0], // 텍스트 영역 가독성 확보
                        ),
                      ),
                    ),

                    // 3. 뱃지
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
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              "BEST",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. 점수 뱃지
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                            const SizedBox(width: 2),
                            Text(
                              score.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 5. 내용 및 좋아요/댓글
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            content,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // ✅ 좋아요 및 댓글 수 표시
                          Row(
                            children: [
                              Icon(Icons.favorite_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text(
                                "$likes",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text(
                                "$comments",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
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

  // ✅ 주석 처리된 위젯들 (호출은 하되 빈 컨테이너 반환)
  Widget _buildQuickTags() => Container();
  Widget _buildThemeCards() => Container();
  Widget _buildCategoryTabs() => Container();
  Widget _buildSubTags() => Container();
  Widget _buildLocationList() => Container();

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
                    // ✅ [디자인 유지] 이미지 없을 때: 브랜드 컬러 배경 + 아이콘
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5), // 연한 보라색 배경
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_rounded, size: 48, color: _brand.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text(
                                "이미지 준비중",
                                style: TextStyle(
                                  color: _brand.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.35),
                            ],
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
                          ],
                        ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _brand.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _brand.withOpacity(0.16)),
                    ),
                    child: Text(
                      '${l10n.needsFine} ${ranking.avgScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: _brand,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Text(
                        '${l10n.reliability} ${ranking.avgTrust.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
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