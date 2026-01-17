import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/core/search_trigger.dart';


// ✅ searchTrigger를 MainShell/ NearbyScreen이 이미 쓰고 있으니 그대로 재사용
// (현재 프로젝트에서 searchTrigger가 선언된 파일에 맞춰 import 경로만 조정하면 됨)
// 보통 너 프로젝트에선 user_mypage_screen.dart에 전역으로 있었으니 show로 가져옴.
import 'package:needsfine_app/screens/user_mypage_screen.dart' show searchTrigger;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();

  // ✅ 더미 데이터(나중에 Supabase stores로 교체)
  final List<_StoreCardVM> _top10 = List.generate(
    10,
        (i) => _StoreCardVM(
      rank: i + 1,
      name: "가게 ${i + 1}",
      category: i % 2 == 0 ? "오마카세" : "스테이크",
      nfScore: 9.2 - (i * 0.2),
      area: i % 2 == 0 ? "강남" : "성수",
    ),
  );

  final List<_CategoryVM> _categories = const [
    _CategoryVM(label: "한식", icon: Icons.rice_bowl_outlined),
    _CategoryVM(label: "일식", icon: Icons.set_meal_outlined),
    _CategoryVM(label: "중식", icon: Icons.local_dining_outlined),
    _CategoryVM(label: "양식", icon: Icons.restaurant_outlined),
    _CategoryVM(label: "오마카세", icon: Icons.stars_outlined),
    _CategoryVM(label: "카페", icon: Icons.coffee_outlined),
    _CategoryVM(label: "바", icon: Icons.wine_bar_outlined),
    _CategoryVM(label: "디저트", icon: Icons.icecream_outlined),
  ];

  final List<_WeeklyRankVM> _weekly = List.generate(
    10,
        (i) => _WeeklyRankVM(
      rank: i + 1,
      name: "주간가게 ${i + 1}",
      changeText: i % 3 == 0 ? "▲${i + 1}" : (i % 3 == 1 ? "▼${i + 1}" : "—"),
      area: i % 2 == 0 ? "홍대" : "을지로",
      nfScore: 8.9 - (i * 0.15),
    ),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    FocusScope.of(context).unfocus();

    // ✅ MainShell이 이 트리거를 감지해서 "내 주변" 탭(인덱스 2)로 이동함
    searchTrigger.value = q;

    // 검색창 비우고 싶으면 주석 해제
    // _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          "NeedsFine",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildSectionTitle("니즈파인 순위 TOP 10")),
          SliverToBoxAdapter(child: _buildTop10Carousel()),
          SliverToBoxAdapter(child: _buildSectionTitle("카테고리별")),
          SliverToBoxAdapter(child: _buildCategoryGrid()),
          SliverToBoxAdapter(child: _buildSectionTitle("주간 니즈파인 랭킹")),
          SliverToBoxAdapter(child: _buildWeeklyList()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withOpacity(0.10),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submitSearch(),
          style: const TextStyle(color: Colors.black, fontSize: 14),
          decoration: InputDecoration(
            hintText: "가게 이름으로 검색 (내 주변에서 보여줘)",
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(Icons.search, color: kNeedsFinePurple),
            suffixIcon: IconButton(
              onPressed: _submitSearch,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: kNeedsFinePurple,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop10Carousel() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        scrollDirection: Axis.horizontal,
        itemCount: _top10.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final s = _top10[i];
          return _TopCard(
            rank: s.rank,
            name: s.name,
            category: s.category,
            area: s.area,
            nfScore: s.nfScore,
            onTap: () {
              // ✅ 탭 시에도 "내 주변"으로 이동 + 해당 가게명으로 검색
              _searchController.text = s.name;
              _submitSearch();
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (context, i) {
          final c = _categories[i];
          return _CategoryTile(
            label: c.label,
            icon: c.icon,
            onTap: () {
              // ✅ 카테고리 탭하면 내 주변으로 이동 + 카테고리로 검색(일단 문자열 검색)
              _searchController.text = c.label;
              _submitSearch();
            },
          );
        },
      ),
    );
  }

  Widget _buildWeeklyList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _weekly.map((w) {
          return _WeeklyRow(
            rank: w.rank,
            name: w.name,
            area: w.area,
            changeText: w.changeText,
            nfScore: w.nfScore,
            onTap: () {
              _searchController.text = w.name;
              _submitSearch();
            },
          );
        }).toList(),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final int rank;
  final String name;
  final String category;
  final String area;
  final double nfScore;
  final VoidCallback onTap;

  const _TopCard({
    required this.rank,
    required this.name,
    required this.category,
    required this.area,
    required this.nfScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kNeedsFinePurple,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    "TOP $rank",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "NF ${nfScore.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$category · $area",
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kNeedsFinePurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeedsFinePurple.withOpacity(0.35)),
              ),
              child: const Text(
                "내 주변에서 보기",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kNeedsFinePurple,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kNeedsFinePurple, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyRow extends StatelessWidget {
  final int rank;
  final String name;
  final String area;
  final String changeText;
  final double nfScore;
  final VoidCallback onTap;

  const _WeeklyRow({
    required this.rank,
    required this.name,
    required this.area,
    required this.changeText,
    required this.nfScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final changeColor = changeText.startsWith("▲")
        ? kNeedsFinePurple
        : (changeText.startsWith("▼") ? Colors.black : Colors.black.withOpacity(0.35));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kNeedsFinePurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$rank",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    area,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.50),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "NF ${nfScore.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  changeText,
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCardVM {
  final int rank;
  final String name;
  final String category;
  final double nfScore;
  final String area;

  _StoreCardVM({
    required this.rank,
    required this.name,
    required this.category,
    required this.nfScore,
    required this.area,
  });
}

class _WeeklyRankVM {
  final int rank;
  final String name;
  final String area;
  final String changeText;
  final double nfScore;

  _WeeklyRankVM({
    required this.rank,
    required this.name,
    required this.area,
    required this.changeText,
    required this.nfScore,
  });
}

class _CategoryVM {
  final String label;
  final IconData icon;

  const _CategoryVM({
    required this.label,
    required this.icon,
  });
}
