import 'package:flutter/material.dart';
import 'package:needsfine_app/widgets/ranking_widget.dart';
import 'package:needsfine_app/main.dart';

// 홈 화면이 탭 전환 시 초기화되지 않도록 함
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  MainCategory _selectedCategory = MainCategory.food;

  // --- Data for new UI ---
  final List<Map<String, dynamic>> coreFoodCategories = const [
    {'icon': Icons.rice_bowl_outlined, 'label': '한식'},
    {'icon': Icons.ramen_dining_outlined, 'label': '일식'},
    {'icon': Icons.tapas_outlined, 'label': '중식'},
    {'icon': Icons.local_pizza_outlined, 'label': '양식'},
    {'icon': Icons.public_outlined, 'label': '아시아'},
    {'icon': Icons.kebab_dining_outlined, 'label': '고기'},
    {'icon': Icons.set_meal_outlined, 'label': '해산물'},
    {'icon': Icons.eco_outlined, 'label': '샐러드'},
    {'icon': Icons.delivery_dining_outlined, 'label': '피자'},
    {'icon': Icons.cake_outlined, 'label': '카페'},
    {'icon': Icons.room_service_outlined, 'label': '파인다이닝'},
    {'icon': Icons.dinner_dining_outlined, 'label': '뷔페'},
    {'icon': Icons.fastfood_outlined, 'label': '치킨'},
    {'icon': Icons.lunch_dining_outlined, 'label': '패스트푸드'},
  ];

  final List<Map<String, dynamic>> coreDrinkCategories = const [
    {'icon': Icons.sports_bar_outlined, 'label': '호프/수제맥주'},
    {'icon': Icons.wine_bar_outlined, 'label': '바'},
    {'icon': Icons.storefront_outlined, 'label': '이자카야'},
    {'icon': Icons.set_meal_outlined, 'label': '해산물주점'},
    {'icon': Icons.flatware_outlined, 'label': '전/파전 주점'},
    {'icon': Icons.holiday_village_outlined, 'label': '포차'},
  ];

  final List<String> situationalTags = const [
    '#데이트 성공확률 높음',
    '#조용한 자리',
    '#혼밥 100% 가능',
    '#줄서먹는집',
    '#가성비갑',
    '#친절함',
    '#사진보다 맛이 진짜임',
    '#술과 같이 하기 좋음'
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final currentCategories = _selectedCategory == MainCategory.food
        ? coreFoodCategories
        : coreDrinkCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            leading: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/location'),
              icon: const Icon(Icons.location_on, size: 18, color: Colors.black),
              label: const Text("현재 위치", style: TextStyle(color: Colors.black)),
            ),
            leadingWidth: 120,
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: notificationCount,
                builder: (context, count, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: Colors.black),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/notification'),
                      ),
                      if (count > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: Text(count.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        ),
                    ],
                  );
                },
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30.0)),
                    child: const Row(children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("'진짜' '맛집'을 '검색'하세요",
                          style: TextStyle(color: Colors.grey))
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // 🔥 실시간 랭킹
          SliverToBoxAdapter(child: RankingWidget()),

          // 🔥 식사/술 카테고리 토글
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  _buildMainCategoryToggle(theme, "식사 🍽️", MainCategory.food),
                  const SizedBox(width: 12),
                  _buildMainCategoryToggle(theme, "술 🍷", MainCategory.drink),
                ],
              ),
            ),
          ),

          // 🔥 카테고리 아이콘
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = currentCategories[index];
                return InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(category['icon'] as IconData,
                          size: 32, color: Colors.grey[700]),
                      const SizedBox(height: 8),
                      Text(category['label'] as String,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }, childCount: currentCategories.length),
            ),
          ),

          // 🔥 태그 추천
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Text(
                "지금 이런 곳은 어때요?",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: situationalTags.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(label: Text(situationalTags[index])),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildMainCategoryToggle(
      ThemeData theme, String text, MainCategory category) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.grey[100],
            border: Border.all(
                color: isSelected ? theme.primaryColor : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.primaryColor : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum MainCategory { food, drink }
