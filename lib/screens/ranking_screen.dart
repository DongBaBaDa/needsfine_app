import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

enum RankingType { personal, store }

class _RankingScreenState extends State<RankingScreen> {
  RankingType _selectedRanking = RankingType.personal;

  // --- Dummy Data ---
  final List<Map<String, dynamic>> userRankings = const [
    {'rank': 1, 'nickname': '리뷰의 신', 'score': 9850},
    {'rank': 2, 'nickname': '맛잘알', 'score': 9700},
    {'rank': 3, 'nickname': '미식가', 'score': 9540},
    {'rank': 4, 'nickname': '탐험가', 'score': 9210},
    {'rank': 5, 'nickname': '프로맛집러', 'score': 8900},
  ];

  final List<Map<String, dynamic>> storeRankings = const [
    {'rank': 1, 'name': '니즈파인 버거', 'category': '양식', 'score': 4.98},
    {'rank': 2, 'name': '마라 선배', 'category': '중식', 'score': 4.95},
    {'rank': 3, 'name': '피자 플레이스', 'category': '양식', 'score': 4.92},
    {'rank': 4, 'name': '진짜 순대국', 'category': '한식', 'score': 4.91},
    {'rank': 5, 'name': '코지 이자카야', 'category': '일식', 'score': 4.89},
  ];

  @override
  Widget build(BuildContext context) {
    final rankings = _selectedRanking == RankingType.personal ? userRankings : storeRankings;

    return Scaffold(
      backgroundColor: Colors.grey[100], // A slightly off-white background to make cards pop
      appBar: AppBar(
        title: const Text('랭킹'),
      ),
      body: Column(
        children: [
          // Modern SegmentedButton for toggling
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SegmentedButton<RankingType>(
              segments: const <ButtonSegment<RankingType>>[
                ButtonSegment<RankingType>(
                    value: RankingType.personal,
                    label: Text('개인'),
                    icon: Icon(Icons.person_outline)),
                ButtonSegment<RankingType>(
                    value: RankingType.store,
                    label: Text('매장'),
                    icon: Icon(Icons.storefront_outlined)),
              ],
              selected: {_selectedRanking},
              onSelectionChanged: (Set<RankingType> newSelection) {
                setState(() {
                  _selectedRanking = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[600],
                selectedBackgroundColor: kNeedsFinePurple.withOpacity(0.1),
                selectedForegroundColor: kNeedsFinePurple,
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
          // List of rankings
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final item = rankings[index];
                if (_selectedRanking == RankingType.personal) {
                  return _buildPersonalRankingCard(context, item);
                } else {
                  return _buildStoreRankingCard(context, item);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRankingCard(BuildContext context, Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.5,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(
              '${user["rank"]}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeedsFinePurple,
              ),
            ),
          ),
        ),
        title: Text(user['nickname']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("${user['score']}점"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, '/user-mypage'),
      ),
    );
  }

  Widget _buildStoreRankingCard(BuildContext context, Map<String, dynamic> store) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.5,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(
              '${store["rank"]}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeedsFinePurple,
              ),
            ),
          ),
        ),
        title: Text(store['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(store['category']!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text("${store['score']}점", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/store-mypage'),
      ),
    );
  }
}
