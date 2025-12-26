import 'package:flutter/material.dart';
import 'package:needsfine_app/widgets/ranking_widget.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final List<String> _filterTabs = ["지역", "음식 종류", "가격", "테이블 타입", "분위기", "편의시설"];
  late final TabController _filterTabController;

  final Set<String> _selectedFilters = {};
  RangeValues _priceRange = const RangeValues(0, 400000);

  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: _filterTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _filterTabController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 1.0,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    TabBar(
                      controller: _filterTabController,
                      isScrollable: true,
                      tabs: _filterTabs.map((String tab) => Tab(text: tab)).toList(),
                      labelColor: kNeedsFinePurple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: kNeedsFinePurple,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        controller: _filterTabController,
                        children: [
                          _buildRegionFilter(scrollController, setModalState),
                          _buildFoodTypeFilter(scrollController, setModalState),
                          _buildPriceFilter(scrollController, setModalState),
                          _buildTableTypeFilter(scrollController, setModalState),
                          _buildMoodFilter(scrollController, setModalState),
                          _buildAmenitiesFilter(scrollController, setModalState),
                        ],
                      ),
                    ),
                    _buildBottomActionArea(setModalState),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('NeedsFine'),
        actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/search'), icon: const Icon(Icons.search))],
      ),
      body: CustomScrollView(slivers: [SliverToBoxAdapter(child: RankingWidget())]),
    );
  }

  // [복원] 누락되었던 필터 위젯 생성 메서드들
  Widget _buildFilterSection({required String title, required List<String> items, required StateSetter setState}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: items.map((item) {
              final isSelected = _selectedFilters.contains(item);
              return ChoiceChip(
                label: Text(item), selected: isSelected,
                onSelected: (selected) => setState(() => selected ? _selectedFilters.add(item) : _selectedFilters.remove(item)),
                selectedColor: kNeedsFinePurple.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? kNeedsFinePurple : Colors.grey.shade300)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionFilter(ScrollController controller, StateSetter setState) {
    return ListView(controller: controller, padding: const EdgeInsets.all(16), children: [
      _buildFilterSection(title: "핫플레이스", items: ["서울", "경기", "인천", "부산", "제주"], setState: setState),
      _buildFilterSection(title: "서울 상세", items: ["강남/역삼/선릉", "강남구청", "건대/군자/구의"], setState: setState),
    ]);
  }

  Widget _buildFoodTypeFilter(ScrollController controller, StateSetter setState) {
    return ListView(controller: controller, padding: const EdgeInsets.all(16), children: [
      _buildFilterSection(title: "🔥 인기메뉴", items: ["스시오마카세", "한우오마카세", "스테이크"], setState: setState),
      _buildFilterSection(title: "국가별", items: ["한식", "중식", "일식", "양식"], setState: setState),
    ]);
  }

  Widget _buildPriceFilter(ScrollController controller, StateSetter setState) {
    return ListView(controller: controller, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ 
        Text("가격", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text("0원 ~ 40만원", style: const TextStyle(color: kNeedsFinePurple, fontWeight: FontWeight.bold))
      ]),
      const SizedBox(height: 16),
      RangeSlider(values: _priceRange, min: 0, max: 400000, divisions: 40, labels: RangeLabels('${(_priceRange.start/10000).toStringAsFixed(0)}만원', '${(_priceRange.end/10000).toStringAsFixed(0)}만원 이상'), onChanged: (values) => setState(() => _priceRange = values), activeColor: kNeedsFinePurple, inactiveColor: Colors.grey[300]),
    ]);
  }

  Widget _buildTableTypeFilter(ScrollController controller, StateSetter setState) {
    final items = [{'icon': Icons.door_front_door_outlined, 'label': '룸'}, {'icon': Icons.countertops_outlined, 'label': '바'}, {'icon': Icons.table_restaurant_outlined, 'label': '홀'}, {'icon': Icons.deck_outlined, 'label': '테라스'}];
    return GridView.builder(controller: controller, padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.9, crossAxisSpacing: 12, mainAxisSpacing: 16), itemCount: items.length, itemBuilder: (context, index) {
      final item = items[index];
      final isSelected = _selectedFilters.contains(item['label']);
      return GestureDetector(onTap: () => setState(() => isSelected ? _selectedFilters.remove(item['label']) : _selectedFilters.add(item['label'] as String)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: isSelected ? kNeedsFinePurple : Colors.grey.shade300, width: isSelected ? 2 : 1), borderRadius: BorderRadius.circular(12), color: isSelected ? kNeedsFinePurple.withOpacity(0.1) : Colors.white), child: Icon(item['icon'] as IconData, size: 32, color: isSelected ? kNeedsFinePurple : Colors.black87)), const SizedBox(height: 8), Text(item['label'] as String, style: TextStyle(color: isSelected ? kNeedsFinePurple : Colors.black87))]));
    });
  }

  Widget _buildMoodFilter(ScrollController controller, StateSetter setState) {
    return ListView(controller: controller, padding: const EdgeInsets.all(16), children: [
      _buildFilterSection(title: "분위기", items: ["데이트", "비즈니스미팅", "기념일", "단체회식"], setState: setState),
    ]);
  }

  Widget _buildAmenitiesFilter(ScrollController controller, StateSetter setState) {
    final items = [{'icon': Icons.local_parking, 'label': '주차가능'}, {'icon': Icons.directions_car, 'label': '발렛가능'}, {'icon': Icons.wine_bar, 'label': '콜키지가능'}];
     return GridView.builder(controller: controller, padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.9, crossAxisSpacing: 12, mainAxisSpacing: 16), itemCount: items.length, itemBuilder: (context, index) {
      final item = items[index];
      final isSelected = _selectedFilters.contains(item['label']);
      return GestureDetector(onTap: () => setState(() => isSelected ? _selectedFilters.remove(item['label']) : _selectedFilters.add(item['label'] as String)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: isSelected ? kNeedsFinePurple : Colors.grey.shade300, width: isSelected ? 2: 1), borderRadius: BorderRadius.circular(12), color: isSelected ? kNeedsFinePurple.withOpacity(0.1) : Colors.white), child: Icon(item['icon'] as IconData, size: 32, color: isSelected ? kNeedsFinePurple : Colors.black87)), const SizedBox(height: 8), Text(item['label'] as String, style: TextStyle(color: isSelected ? kNeedsFinePurple : Colors.black87))]));
    });
  }

  Widget _buildBottomActionArea(StateSetter setState) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]), child: Row(children: [OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text("초기화"), onPressed: () => setState(() => _selectedFilters.clear()), style: OutlinedButton.styleFrom(foregroundColor: kNeedsFinePurple, side: const BorderSide(color: kNeedsFinePurple))), const SizedBox(width: 8), Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: kNeedsFinePurple, foregroundColor: Colors.white), child: const Text("결과 보기")))]));
  }
}
