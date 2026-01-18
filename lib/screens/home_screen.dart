import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/core/search_trigger.dart'; // SearchTarget import 확인

import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';

import 'package:needsfine_app/screens/category_placeholder_screen.dart';
import 'package:needsfine_app/screens/weekly_ranking_screen.dart';

import 'package:needsfine_app/widgets/notification_badge.dart';

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

  // ✅ 주간 랭킹: 리뷰 메뉴(랭킹)에서 불러오는 값과 동일한 소스(ReviewService.fetchStoreRankings)
  // 홈에서는 5개 미리보기, 더보기는 100개.
  List<StoreRanking> _top100 = [];

  /// storeName -> imageUrl
  final Map<String, String> _storeImageMap = {};

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final rankings = await ReviewService.fetchStoreRankings();

      // 안전 정렬: 니즈파인 점수 기준 내림차순
      final sorted = List<StoreRanking>.from(rankings);
      sorted.sort((a, b) => b.avgScore.compareTo(a.avgScore));

      final top100 = sorted.take(100).toList();

      // 랭크 재부여 (1~N)
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

      // 이미지 맵 로드 (top100 기준)
      final names = top100.map((e) => e.storeName).where((e) => e.isNotEmpty).toSet().toList();
      final imageMap = await _fetchStoreImages(names);

      if (mounted) {
        setState(() {
          _top100 = top100;
          _storeImageMap
            ..clear()
            ..addAll(imageMap);
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
      // ✅ stores 테이블: name, image_url 가정
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
      debugPrint("매장 이미지 로드 실패: $e");
      return {};
    }
  }

  void _submitSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) return;

    // ✅ [수정] 전역 트리거로 Nearby 탭 이동 (SearchTarget 객체 사용)
    searchTrigger.value = SearchTarget(query: query);

    FocusScope.of(context).unfocus();
  }

  void _goToWeeklyMore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyRankingScreen(
          rankings: _top100,
          storeImageMap: _storeImageMap,
        ),
      ),
    );
  }

  void _goToCategory(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPlaceholderScreen(title: title),
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '가게명/주소로 검색',
            hintStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
            prefixIcon: const Icon(Icons.search, color: kNeedsFinePurple),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
              onPressed: () => _submitSearch(_searchController.text),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = <_CategoryItem>[
      _CategoryItem('한식', Icons.restaurant_rounded),
      _CategoryItem('일식', Icons.set_meal_rounded),
      _CategoryItem('중식', Icons.ramen_dining_rounded),
      _CategoryItem('양식', Icons.local_pizza_rounded),
      _CategoryItem('카페', Icons.local_cafe_rounded),
      _CategoryItem('술집', Icons.wine_bar_rounded),
      _CategoryItem('디저트', Icons.cake_rounded),
      _CategoryItem('패스트푸드', Icons.fastfood_rounded),
      _CategoryItem('분식', Icons.soup_kitchen_rounded),
      _CategoryItem('기타', Icons.more_horiz_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: categories.map((c) {
          return _CategoryChip(
            label: c.label,
            icon: c.icon,
            onTap: () => _goToCategory(c.label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyHorizontal() {
    if (_top100.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Text("아직 주간 랭킹 데이터가 없습니다.", style: TextStyle(color: Colors.grey)),
      );
    }

    final preview = _top100.take(5).toList();

    return SizedBox(
      height: 255,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        scrollDirection: Axis.horizontal,
        itemCount: preview.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final r = preview[index];
          final imageUrl = _storeImageMap[r.storeName] ?? '';

          return SizedBox(
            width: 280,
            child: _WeeklyRankCard(
              ranking: r,
              imageUrl: imageUrl,
              onTap: () {
                if (r.storeName.isNotEmpty) {
                  // ✅ [수정] SearchTarget 객체 전달
                  searchTrigger.value = SearchTarget(query: r.storeName);
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 18,
        title: const Text(
          '니즈파인 NeedsFine',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        actions: [
          // ✅ 새로고침 버튼 -> 알림 버튼으로 교체
          NotificationBadge(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: kNeedsFinePurple,
        onRefresh: _loadHomeData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kNeedsFinePurple))
            : ListView(
          children: [
            _buildSearchBar(),

            _sectionTitle('카테고리별'),
            _buildCategoryGrid(),

            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),

            _sectionTitle(
              '주간 니즈파인 랭킹',
              trailing: TextButton(
                onPressed: _goToWeeklyMore,
                child: const Text(
                  '더 보기+',
                  style: TextStyle(color: kNeedsFinePurple, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            _buildWeeklyHorizontal(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;
  _CategoryItem(this.label, this.icon);
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.grey.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: kNeedsFinePurple),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyRankCard extends StatelessWidget {
  final StoreRanking ranking;
  final String imageUrl;
  final VoidCallback onTap;

  const _WeeklyRankCard({
    required this.ranking,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ topTags nullable 대응
    final tags = (ranking.topTags ?? const <String>[]).take(2).toList();
    final tagText = tags.isEmpty ? '' : tags.join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) "1위 ㅇㅇㅇ"
            Text(
              '${ranking.rank}위 ${ranking.storeName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 12),

            // 2) Pill 2개 (✅ Row 대신 Wrap → 오버플로우 방지)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pill(
                  label: '니즈파인 점수 NF ${ranking.avgScore.toStringAsFixed(1)}',
                  filled: true,
                ),
                _Pill(
                  label: '신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%',
                  filled: false,
                ),
              ],
            ),

            if (tagText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                tagText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],

            const SizedBox(height: 12),

            // 3) 사진 영역 (큰 박스)
            Expanded(
              child: _StoreImageLarge(url: imageUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool filled;

  const _Pill({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? kNeedsFinePurple : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? kNeedsFinePurple : Colors.grey.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StoreImageLarge extends StatelessWidget {
  final String url;

  const _StoreImageLarge({required this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        color: Colors.grey.withOpacity(0.08),
        child: hasUrl
            ? Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(Icons.store_rounded, color: Colors.black, size: 42),
    );
  }
}