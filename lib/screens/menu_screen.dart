import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  // 메뉴 데이터 (이름, 아이콘)
  final List<Map<String, dynamic>> menuItems = const [
    {"title": "전체보기", "icon": Icons.grid_view},
    {"title": "1인분", "icon": Icons.person},
    {"title": "한식", "icon": Icons.rice_bowl},
    {"title": "분식", "icon": Icons.ramen_dining},
    {"title": "카페·디저트", "icon": Icons.coffee},
    {"title": "돈까스·회", "icon": Icons.dining},
    {"title": "치킨", "icon": Icons.flutter_dash}, // 치킨 아이콘 대용
    {"title": "피자", "icon": Icons.local_pizza},
    {"title": "아시안", "icon": Icons.soup_kitchen},
    {"title": "중식", "icon": Icons.restaurant},
    {"title": "족발·보쌈", "icon": Icons.dinner_dining},
    {"title": "야식", "icon": Icons.nights_stay},
    {"title": "채식", "icon": Icons.eco},
    {"title": "도시락", "icon": Icons.bento},
    {"title": "맛집랭킹", "icon": Icons.emoji_events},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("메뉴 선택"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "무엇을 드시겠어요?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // [🔥 핵심] 그리드 뷰 (바둑판 배열)
            Expanded(
              child: GridView.builder(
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 한 줄에 4개씩
                  mainAxisSpacing: 20, // 위아래 간격
                  crossAxisSpacing: 10, // 좌우 간격
                  childAspectRatio: 0.8, // 아이템 비율 (세로가 조금 더 길게)
                ),
                itemBuilder: (context, index) {
                  return _buildMenuItem(context, menuItems[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메뉴 아이템 위젯
  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        // 클릭 시 성지 화면 등으로 이동하거나 개발중 메시지
        if (item["title"] == "맛집랭킹") {
          // 예시: 맛집랭킹 누르면 아까 만든 성지 화면으로 이동
          Navigator.pushNamed(context, '/sanctuary');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${item['title']} 메뉴는 준비 중입니다! 🍳"), duration: const Duration(seconds: 1)),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 박스
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100], // 연한 회색 배경
              borderRadius: BorderRadius.circular(20), // 둥근 모서리
            ),
            child: Icon(item['icon'], size: 30, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          // 메뉴 이름
          Text(
            item['title'],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}