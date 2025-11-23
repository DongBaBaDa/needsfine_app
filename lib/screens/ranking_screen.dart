import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

enum RankingType { personal, store }

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  RankingType _selectedRanking = RankingType.personal;

  // 반짝 애니메이션용 컨트롤러
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

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
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankings = _selectedRanking == RankingType.personal
        ? userRankings
        : storeRankings;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("랭킹")),
      body: Column(
        children: [
          // 이 부분만 수정됨
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _glowAnimation,
                  child: const Text(
                    "⏱ 실시간 업데이트 자동 반영 중",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                _buildToggle(),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final item = rankings[index];
                if (index < 3) {
                  return _buildTopCard(item);
                } else {
                  return _buildNormalCard(item);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return SegmentedButton<RankingType>(
      segments: const [
        ButtonSegment(value: RankingType.personal, label: Text("개인"), icon: Icon(Icons.person_outline)),
        ButtonSegment(value: RankingType.store, label: Text("매장"), icon: Icon(Icons.storefront_outlined)),
      ],
      selected: {_selectedRanking},
      onSelectionChanged: (sel) => setState(() => _selectedRanking = sel.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kNeedsFinePurple.withOpacity(0.15),
        selectedForegroundColor: kNeedsFinePurple,
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildTopCard(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context,
            _selectedRanking == RankingType.personal
                ? '/public-profile'
                : '/store-detail'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRankBadge(item['rank']),
                    const SizedBox(height: 4),
                    Text(
                      item['nickname'] ?? item['name'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedRanking == RankingType.personal
                          ? "점수: ${item['score']}"
                          : "${item['category']} • ${item['score']}점",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRankBadge(int rank) {
    const badges = ["🥇 1위", "🥈 2위", "🥉 3위"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kNeedsFinePurple,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        badges[rank - 1],
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildNormalCard(Map<String, dynamic> item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Text(
          "${item['rank']}",
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: kNeedsFinePurple),
        ),
        title: Text(item['nickname'] ?? item['name']),
        subtitle: _selectedRanking == RankingType.personal
            ? Text("점수: ${item['score']}")
            : Text("${item['category']} • ${item['score']}점"),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context,
            _selectedRanking == RankingType.personal
                ? '/public-profile'
                : '/store-detail'),
      ),
    );
  }
}
