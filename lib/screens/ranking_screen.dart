import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

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
      appBar: AppBar(
        title: const Text('랭킹'),
      ),
      body: ListView.builder(
        itemCount: userRankings.length,
        itemBuilder: (context, index) {
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
                  // As assets are empty, this will show an error if not commented out
                  // backgroundImage: AssetImage(user['icon']!),
                  child: Text(user['nickname']![0]),
                ),
              ],
            ),
            title: Text(user['nickname']!),
            subtitle: Text("${user['score']}점"),
            onTap: () {},
          );
        },
      ),
    );
  }
}
