import 'package:flutter/material.dart';
import 'package:needsfine_app/widgets/ranking_widget.dart';
import 'package:needsfine_app/main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Data for menu categories
  final List<Map<String, dynamic>> menuCategories = const [
    {'icon': Icons.person_outline, 'label': '1인분'},
    {'icon': Icons.local_pizza_outlined, 'label': '피자'},
    {'icon': Icons.fastfood_outlined, 'label': '치킨'},
    {'icon': Icons.ramen_dining_outlined, 'label': '일식'},
    {'icon': Icons.tapas_outlined, 'label': '중식'},
    {'icon': Icons.rice_bowl_outlined, 'label': '한식'},
    {'icon': Icons.cake_outlined, 'label': '디저트'},
    {'icon': Icons.nightlife, 'label': '야식'},
    {'icon': Icons.local_bar_outlined, 'label': '술집'},
    {'icon': Icons.more_horiz, 'label': '더보기'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        icon: const Icon(Icons.notifications_none, color: Colors.black),
                        onPressed: () => Navigator.pushNamed(context, '/notification'),
                      ),
                      if (count > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("'진짜' '맛집'을 '검색'하세요", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Real-time search ranking widget
          SliverToBoxAdapter(
            child: RankingWidget(),
          ),
          // Menu Category Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = menuCategories[index];
                  return InkWell(
                    onTap: () {
                      // TODO: Navigate to category-specific screen
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category['icon'] as IconData, size: 32),
                        const SizedBox(height: 8),
                        Text(category['label'] as String),
                      ],
                    ),
                  );
                },
                childCount: menuCategories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
