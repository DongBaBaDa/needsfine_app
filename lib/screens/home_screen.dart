import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/screens/category_placeholder_screen.dart';
import 'package:needsfine_app/screens/weekly_ranking_screen.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';

// ✅ 지역 데이터 및 다국어 임포트
import 'package:needsfine_app/data/korean_regions.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

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

  List<StoreRanking> _top100 = [];
  final Map<String, String> _storeImageMap = {};

  // ✅ 배너 데이터 리스트
  List<String> _bannerList = [];

  int _currentBannerIndex = 0;
  int _selectedCategoryIndex = 0; // 0:종류, 1:테마, 2:지역
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  // ✅ [NEW] 지역 선택 상태
  String? _selectedProvince;

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
      // 1. 배너 데이터 로드 (DB 연동)
      final bannerData = await _supabase
          .from('banners')
          .select('image_url')
          .order('created_at', ascending: true);

      final List<String> loadedBanners = [];
      for (var row in bannerData) {
        loadedBanners.add(row['image_url'] as String);
      }

      // 2. 랭킹 데이터 로드
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

      // 3. 매장 이미지 로드
      final names = top100.map((e) => e.storeName).where((e) => e.isNotEmpty).toSet().toList();
      final imageMap = await _fetchStoreImages(names);

      if (mounted) {
        setState(() {
          _bannerList = loadedBanners; // 배너 리스트 갱신
          _top100 = top100;
          _storeImageMap..clear()..addAll(imageMap);
        });
      }
    } catch (e) {
      debugPrint("홈 데이터 로드 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> _fetchStoreImages(List<String> storeNames) async {
    if (storeNames.isEmpty) return {};
    try {
      final res = await _supabase.from('stores').select('name, image_url').inFilter('name', storeNames);
      final map = <String, String>{};
      if (res is List) {
        for (final row in res) {
          final name = (row['name'] ?? '').toString();
          final url = (row['image_url'] ?? '').toString();
          if (name.isNotEmpty && url.isNotEmpty) {
            map[name] = url;
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

  void _goToCategory(String title) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPlaceholderScreen(title: title)));
  }

  void _searchByRegion(String regionName) {
    searchTrigger.value = SearchTarget(query: regionName);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$regionName(으)로 검색합니다.")));
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

            _buildAdBanner(), // ✅ 0/0 처리 적용
            const SizedBox(height: 24),

            _buildCategoryTabs(),
            const SizedBox(height: 16),

            AnimatedCrossFade(
              firstChild: _buildCategoryGrid(l10n),
              secondChild: _selectedCategoryIndex == 1
                  ? _buildThemeList()
                  : _buildLocationList(),
              crossFadeState: _selectedCategoryIndex == 0
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),

            const SizedBox(height: 32),
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
            hintText: '맛집을 찾아보세요',
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
    // ✅ 배너가 없을 때 (0개) 처리
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
                  borderRadius: BorderRadius.circular(16),
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
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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

            // ✅ 인디케이터 (0/0)
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

  Widget _buildCategoryTabs() {
    final tabs = ["종류별", "테마별", "지역별"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                  if (index != 2) _selectedProvince = null;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _brand : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _brand.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCategoryGrid(AppLocalizations l10n) {
    final categories = [
      (l10n.koreanFood, Icons.restaurant_menu),
      (l10n.japaneseFood, Icons.set_meal),
      (l10n.chineseFood, Icons.ramen_dining),
      (l10n.westernFood, Icons.local_pizza),
      (l10n.cafe, Icons.local_cafe),
      ('술집', Icons.local_bar),
      (l10n.dessert, Icons.icecream),
      (l10n.fastFood, Icons.fastfood),
      (l10n.snackFood, Icons.soup_kitchen),
      ('기타', Icons.more_horiz),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _CategoryChip(
              label: c.$1,
              icon: c.$2,
              onTap: () => _goToCategory(c.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeList() {
    final themes = ["데이트 맛집", "가족 외식", "혼밥 추천", "회식 장소", "뷰 맛집"];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(themes[index]),
            backgroundColor: Colors.white,
            onPressed: () => _submitSearch(themes[index]),
            side: BorderSide(color: Colors.grey.shade300),
          );
        },
      ),
    );
  }

  Widget _buildLocationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: koreanRegions.keys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final province = koreanRegions.keys.elementAt(index);
              final isSelected = _selectedProvince == province;
              return ChoiceChip(
                label: Text(province),
                selected: isSelected,
                selectedColor: _brand.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? _brand : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedProvince = selected ? province : null;
                  });
                },
                backgroundColor: Colors.white,
                side: BorderSide(color: isSelected ? _brand : Colors.grey.shade300),
              );
            },
          ),
        ),

        if (_selectedProvince != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$_selectedProvince 상세 지역", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: koreanRegions[_selectedProvince]!.map((city) {
                    return InkWell(
                      onTap: () => _searchByRegion("$_selectedProvince $city"),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(city, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ]
      ],
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

class _CategoryChip extends StatelessWidget {
  static const Color _brand = Color(0xFF8A2BE2);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _brand.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _brand.withOpacity(0.18)),
              ),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ],
        ),
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
                        color: Colors.grey[100],
                        child: const Icon(Icons.store, color: Colors.grey),
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