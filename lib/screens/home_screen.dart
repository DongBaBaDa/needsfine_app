import 'package:flutter/material.dart';
import 'package:needsfine_app/widgets/ranking_widget.dart';
import 'package:needsfine_app/main.dart'; // Reverted import

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> userRankings = const [
    {'rank': 1, 'nickname': '리뷰의 신', 'score': 9850, 'icon': 'assets/images/painy.png'},
    {'rank': 2, 'nickname': '맛잘알', 'score': 9700, 'icon': 'assets/images/painy2.png'},
    {'rank': 3, 'nickname': '미식가', 'score': 9540, 'icon': 'assets/images/painy3.png'},
    {'rank': 4, 'nickname': '탐험가', 'score': 9210, 'icon': 'assets/images/painy.png'},
    {'rank': 5, 'nickname': '프로맛집러', 'score': 8900, 'icon': 'assets/images/painy2.png'},
    {'rank': 6, 'nickname': '신입', 'score': 8750, 'icon': 'assets/images/painy3.png'},
    {'rank': 7, 'nickname': 'NeedsFineUser123', 'score': 8600, 'icon': 'assets/images/painy.png'},
    {'rank': 8, 'nickname': '숨은고수', 'score': 8450, 'icon': 'assets/images/painy2.png'},
    {'rank': 9, 'nickname': '단골손님', 'score': 8200, 'icon': 'assets/images/painy3.png'},
    {'rank': 10, 'nickname': '새내기', 'score': 8100, 'icon': 'assets/images/painy.png'},
    {'rank': 11, 'nickname': '리뷰어', 'score': 7950, 'icon': 'assets/images/painy2.png'},
    {'rank': 12, 'nickname': '맛집찾아삼만리', 'score': 7800, 'icon': 'assets/images/painy3.png'},
    {'rank': 13, 'nickname': '냠냠', 'score': 7650, 'icon': 'assets/images/painy.png'},
    {'rank': 14, 'nickname': '쩝쩝박사', 'score': 7500, 'icon': 'assets/images/painy2.png'},
    {'rank': 15, 'nickname': '푸드파이터', 'score': 7350, 'icon': 'assets/images/painy3.png'},
    {'rank': 16, 'nickname': '또왔어요', 'score': 7200, 'icon': 'assets/images/painy.png'},
    {'rank': 17, 'nickname': '하이', 'score': 7050, 'icon': 'assets/images/painy2.png'},
    {'rank': 18, 'nickname': '헬로', 'score': 6900, 'icon': 'assets/images/painy3.png'},
    {'rank': 19, 'nickname': '반가워요', 'score': 6750, 'icon': 'assets/images/painy.png'},
    {'rank': 20, 'nickname': '마지막주자', 'score': 6600, 'icon': 'assets/images/painy2.png'},
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
          SliverToBoxAdapter(
            child: RankingWidget(), 
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                "니즈파인 랭킹",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = userRankings[index];
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 30, 
                        child: Text(
                          '${user["rank"]}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundImage: AssetImage(user['icon']!),
                      ),
                    ],
                  ),
                  title: Text(user['nickname']!),
                  subtitle: Text("${user['score']}점"),
                  onTap: () {},
                );
              },
              childCount: userRankings.length,
            ),
          ),
        ],
      ),
    );
  }
}
