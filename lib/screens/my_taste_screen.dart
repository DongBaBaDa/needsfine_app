import 'package:flutter/material.dart';
import 'my_taste_detail_screen.dart';
import 'my_taste_report_screen.dart';
import 'my_taste_history_screen.dart';

class MyTasteScreen extends StatefulWidget {
  const MyTasteScreen({super.key});

  @override
  State<MyTasteScreen> createState() => _MyTasteScreenState();
}

class _MyTasteScreenState extends State<MyTasteScreen> {
  // 카테고리 목록
  final List<Map<String, dynamic>> categories = [
    {
      "name": "한식",
      "color": Colors.redAccent,
      "open": false,
      "items": {
        "두루치기": 2,
        "제육볶음": 3,
        "비빔밥": 1,
      },
    },
    {
      "name": "일식",
      "color": Colors.blueAccent,
      "open": false,
      "items": {
        "초밥": 6,
        "회": 4,
      },
    },
    {
      "name": "중식",
      "color": Colors.orange,
      "open": false,
      "items": {
        "짜장면": 4,
        "탕수육": 2,
        "마라탕": 1,
      }
    },
    {
      "name": "양식",
      "color": Colors.green,
      "open": false,
      "items": {
        "파스타": 3,
        "스테이크": 2,
        "피자": 4,
      }
    },
    {
      "name": "패스트푸드",
      "color": Colors.purple,
      "open": false,
      "items": {
        "버거": 5,
        "감자튀김": 3,
        "치킨너겟": 2,
      }
    },
    {
      "name": "건강식",
      "color": Colors.teal,
      "open": false,
      "items": {
        "샐러드": 4,
        "스무디": 2,
      }
    },
    {
      "name": "디저트",
      "color": Colors.pinkAccent,
      "open": false,
      "items": {
        "케이크": 4,
        "아이스크림": 3,
      }
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("나의 입맛"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTasteReportScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTasteHistoryScreen()),
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 📌 카테고리들 출력
          for (int i = 0; i < categories.length; i++)
            _buildCategory(categories[i]),

          const SizedBox(height: 20),

          // 📌 다음 단계 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTasteDetailScreen()),
            ),
            child: const Text(
              "다음 단계",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(Map data) {
    int totalCount =
    data["items"].values.fold(0, (sum, val) => sum + val);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: data["color"].withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 🔥 카테고리 상단
          ListTile(
            title: Text(
              data["name"],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("$totalCount", style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                const RotatedBox(
                    quarterTurns: 1, child: Icon(Icons.chevron_right)),
              ],
            ),
            onTap: () {
              setState(() {
                data["open"] = !data["open"];
              });
            },
          ),

          // 🔥 하위 메뉴 펼치기
          if (data["open"]) _buildSubMenu(data),
        ],
      ),
    );
  }

  Widget _buildSubMenu(Map data) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var entry in data["items"].entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restaurant),
              title: Text(entry.key),
              trailing: Text("${entry.value}회"),
            )
        ],
      ),
    );
  }
}