import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:math';

// Data model for a store
class Store {
  final int rank;
  final String name;
  final double distance;
  final int reviewCount;
  final double needsFineScore;
  final List<String> tags;

  Store({
    required this.rank,
    required this.name,
    required this.distance,
    required this.reviewCount,
    required this.needsFineScore,
    required this.tags,
  });
}

class SanctuaryScreen extends StatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  State<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends State<SanctuaryScreen> {
  final ItemScrollController _scrollController = ItemScrollController();
  int _currentCategoryIndex = 0;
  String _selectedFilter = "니즈파인 순"; // Default filter

  final List<String> _categories = [
    "데이트", "점심", "저녁", "가족", "가성비", "헌팅", "모임", "야식", "고급"
  ];
  final List<String> _filters = ["니즈파인 순", "가까운 거리순", "리뷰 많은 순", "예약률 순", "신규 매장순"];

  late Map<String, List<Store>> _storesByCategory;
  late List<Store> _currentStores;

  @override
  void initState() {
    super.initState();
    _storesByCategory = _generateDummyData();
    _currentStores = List.from(_storesByCategory[_categories[_currentCategoryIndex]]!);
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case "니즈파인 순":
          _currentStores.sort((a, b) => a.rank.compareTo(b.rank));
          break;
        case "가까운 거리순":
          _currentStores.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case "리뷰 많은 순":
          _currentStores.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
          break;
        default:
          _currentStores.sort((a, b) => a.rank.compareTo(b.rank));
          break;
      }
    });
  }

  Map<String, List<Store>> _generateDummyData() {
    final random = Random();
    final Map<String, List<Store>> data = {};
    final List<String> allTags = [
      "가성비", "가심비", "혼밥", "혼술", "데이트", "기념일", "소개팅", "상견례", "가족외식", "단체모임", "회식", "접대", 
      "조용한", "분위기 좋은", "시끄러운", "활기찬", "힙한", "감성적인", "이국적인", "전통적인",
      "전망좋은", "야경", "루프탑", "테라스", "야외", "주차가능", "발렛파킹", "예약가능", "콜키지프리",
      "룸", "애견동반", "유아동반", "유아시설", "장애인시설", "신규오픈", "현지인맛집", "노포",
      "대체불가", "사장님존잘", "사장님존예", "친절한", "매장청결", "음식빨리나옴",
      "재료신선", "양많음", "존맛탱", "인생맛집"
    ];

    for (var category in _categories) {
      data[category] = List.generate(10, (index) {
        final tagCount = random.nextInt(10) + 1;
        final shuffledTags = [...allTags]..shuffle(random);
        return Store(
          rank: index + 1,
          name: "$category 맛집 ${index + 1}호점",
          distance: double.parse((random.nextDouble() * 10).toStringAsFixed(1)),
          reviewCount: random.nextInt(1000) + 20,
          needsFineScore: double.parse((random.nextDouble() * 2 + 2.5).toStringAsFixed(1)),
          tags: shuffledTags.sublist(0, tagCount),
        );
      });
    }
    return data;
  }
  
  void _onCategoryTapped(int index) {
    final int listIndex = (index % _categories.length);
    setState(() {
      _currentCategoryIndex = listIndex;
      _currentStores = List.from(_storesByCategory[_categories[listIndex]]!);
      _applyFilter(); 
    });
    _scrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      alignment: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white, 
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0), // Add left padding for the title
          child: Text("성지", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildCategoryList(),
          const SizedBox(height: 10),
          _buildFilterButton(),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _currentStores.length,
              itemBuilder: (context, index) {
                  final store = _currentStores[index];
                  return StoreListItem(store: store); 
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryList() {
      final int itemCount = 1000;
      final screenWidth = MediaQuery.of(context).size.width;
      return SizedBox(
          height: 40,
          child: ScrollablePositionedList.builder(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 2.5), // Adjusted padding for centering
              initialScrollIndex: itemCount ~/ 2,
              itemScrollController: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                  final categoryIndex = index % _categories.length;
                  bool isSelected = _currentCategoryIndex == categoryIndex;
                  return GestureDetector(
                      onTap: () => _onCategoryTapped(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text(
                                    _categories[categoryIndex],
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.blue : Colors.grey,
                                    ),
                                ),
                                const SizedBox(height: 4),
                                if (isSelected)
                                    Container(
                                        height: 2,
                                        width: 40, 
                                        color: Colors.blue,
                                    )
                            ],
                        ),
                      ),
                  );
              },
          ),
      );
  }


  Widget _buildFilterButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: InkWell(
          onTap: () => _showFilterModal(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedFilter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("매장 정렬", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                      ],
                    ),
                  ),
                  ..._filters.map((filter) {
                    bool isSelected = _selectedFilter == filter;
                    return ListTile(
                      title: Text(
                        filter,
                        style: TextStyle(color: isSelected ? Colors.blue : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilter();
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ],
              ),
            );
          }
        );
      },
    );
  }
}

class CrownPainter extends CustomPainter {
  final Color color;
  CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.9, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StoreListItem extends StatelessWidget {
  final Store store;

  const StoreListItem({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/store-detail', arguments: '1'); // TODO: Use actual store id
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none, // Allow crown to overflow
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.store, size: 60, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: -12,
                  right: 15,
                  child: _buildRankBadge(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        store.needsFineScore.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Text("(${store.reviewCount})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("현재 위치로부터 ${store.distance}km", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: store.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      backgroundColor: Colors.grey[200],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    if (store.rank <= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              "${store.rank}위",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );
    } else {
        Color badgeColor = const Color(0xFFFEE1E1); 
        Color textColor = const Color(0xFFD32F2F); 

        return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
            Positioned(
                top: -3,
                child: CustomPaint(
                size: const Size(22, 11),
                painter: CrownPainter(color: badgeColor),
                ),
            ),
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                ),
                child: Center(
                child: Text(
                    "${store.rank}위",
                    style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                ),
                ),
            ),
            ],
        ),
        );
    }
  }
}
