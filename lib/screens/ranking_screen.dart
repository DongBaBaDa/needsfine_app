import 'package:flutter/material.dart';

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
    {'rank': 1, 'nickname': '리뷰의 신', 'score': 9850, 'icon': 'assets/images/painy.png'},
    {'rank': 2, 'nickname': '맛잘알', 'score': 9700, 'icon': 'assets/images/painy2.png'},
    // ... (rest of the user rankings)
  ];

  final List<Map<String, dynamic>> storeRankings = const [
    {'rank': 1, 'name': '니즈파인 버거', 'category': '양식', 'score': 4.98},
    {'rank': 2, 'name': '마라 선배', 'category': '중식', 'score': 4.95},
    {'rank': 3, 'name': '피자 플레이스', 'category': '양식', 'score': 4.92},
    // ... (add more store rankings if needed)
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankings = _selectedRanking == RankingType.personal ? userRankings : storeRankings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('랭킹'),
        actions: [
          _buildRankingToggle(theme),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.builder(
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final item = rankings[index];
          if (_selectedRanking == RankingType.personal) {
            return _buildPersonalRankingTile(context, item);
          } else {
            return _buildStoreRankingTile(context, item);
          }
        },
      ),
    );
  }

  Widget _buildRankingToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleButton(theme, '개인', RankingType.personal),
          _buildToggleButton(theme, '매장', RankingType.store),
        ],
      ),
    );
  }

  Widget _buildToggleButton(ThemeData theme, String text, RankingType type) {
    final isSelected = _selectedRanking == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRanking = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalRankingTile(BuildContext context, Map<String, dynamic> user) {
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
            child: Text(user['nickname']![0]),
          ),
        ],
      ),
      title: Text(user['nickname']!),
      subtitle: Text("${user['score']}점"),
      onTap: () {},
    );
  }

  Widget _buildStoreRankingTile(BuildContext context, Map<String, dynamic> store) {
    return ListTile(
      leading: SizedBox(
        width: 30,
        child: Text(
          '${store["rank"]}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(store['name']!),
      subtitle: Text(store['category']!),
      trailing: Text("${store['score']}점", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
      onTap: () {},
    );
  }
}
