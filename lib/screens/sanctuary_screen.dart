import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';

class SanctuaryScreen extends StatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  State<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends State<SanctuaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = [
    "족발·보쌈", "찜·탕", "분식", "카페·디저트", "패스트푸드", "피자", "치킨"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextButton.icon(
          icon: const Icon(Icons.flag, color: Colors.blue),
          label: const Text("니즈파인 성지", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigator.pushNamed(context, '/search');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: _categories.map((String category) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 5,
            itemBuilder: (context, index) {
              return StoreListItem(
                category: category,
                index: index,
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class StoreListItem extends StatelessWidget {
  final String category;
  final int index;

  const StoreListItem({
    super.key,
    required this.category,
    required this.index,
  });

  final List<int> dummyCount = const [1, 2, 3];

  @override
  Widget build(BuildContext context) {
    // [4번 수정 완료] 클릭 시 상세 화면으로 이동
    return GestureDetector(
      onTap: () {
        // 더미 데이터 연결: 짝수는 1번 가게(족발), 홀수는 2번 가게(떡볶이)로 연결
        String storeId = (index % 2 == 0) ? '1' : '2';
        Navigator.pushNamed(context, '/store-detail', arguments: storeId);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12, // 투명도 조절된 검은색
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 슬라이더 (아이콘 대체)
            CarouselSlider(
              options: CarouselOptions(
                height: 180,
                viewportFraction: 1,
                autoPlay: true,
              ),
              items: dummyCount.map((_) {
                return Container(
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.store, size: 60, color: Colors.white),
                );
              }).toList(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, color: Colors.purple, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "성지 순례 필수 코스",
                            style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  if (index == 0) const SizedBox(height: 8),

                  Text(
                    "$category 맛집 ${index + 1}호점",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 18),
                      const SizedBox(width: 4),
                      const Text("4.9 (인증된 맛집)"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Row(
                    children: [
                      Text("15분", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      Text(" · 1.2km", style: TextStyle(color: Colors.grey)),
                    ],
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