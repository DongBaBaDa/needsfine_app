import 'package:flutter/material.dart';
import 'package:needsfine_app/widgets/ranking_widget.dart'; // [!] '../widgets/' 경로로 수정
import 'package:needsfine_app/main.dart'; // [!] 전역 변수(notificationCount) 때문에 임시로 Import

// --- [ ✅ ✅ 3. '홈' '화면' ] ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                valueListenable: notificationCount, // [!] main.dart의 전역 변수 참조
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
            child: RankingWidget(), // [!] 분리된 위젯
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")),
                  title: Text("'AI'가 '검증'한 '매장' ${index + 1}"),
                  subtitle: const Text("홀 4.5 / 배달 2.8"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                );
              },
              childCount: 10,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Top 10 NeedsFine 매장",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(right: 10),
                          child: Container(
                            width: 100,
                            height: 100,
                            alignment: Alignment.center,
                            child: Text("매장 ${index+1}"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 100,
              color: Colors.grey[300],
              margin: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: const Text("'광고' '배너' ('AI 탐정' '인증' '존') '공간'"),
            ),
          ),
        ],
      ),
    );
  }
}