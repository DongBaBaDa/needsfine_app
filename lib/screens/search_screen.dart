import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class SearchScreen extends StatefulWidget {
  final String? initialSearchTerm;
  const SearchScreen({super.key, this.initialSearchTerm});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;

  // Dummy data based on the provided design
  final List<String> _popularSearches = [
    '데이트 맛집', '회식 장소', '혼밥 추천', '한식 뷔페', '스시 오마카세', '이자카야',
  ];
  List<String> _recentSearches = [
    '강남역 맛집', '압구정 카페', '홍대 술집', '성수동 브런치',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _recentSearches.remove(query);
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) { // Limit recent searches
          _recentSearches.removeLast();
        }
      });
      Navigator.pushNamed(context, '/search-result', arguments: query.trim());
    }
  }

  void _deleteRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "'진짜' '맛집'을 '검색'하세요",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () => _searchController.clear(),
                      )
                    : const SizedBox.shrink();
                },
              ),
            ),
            onSubmitted: _performSearch,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
            child: ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeedsFinePurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('검색'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (_recentSearches.isNotEmpty)
            _buildSection(
              icon: Icons.history,
              title: '최근 검색어',
              action: TextButton(
                onPressed: _clearAllRecentSearches,
                child: const Text('전체 삭제', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              child: Column(
                children: _recentSearches.map((term) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(term, style: const TextStyle(fontSize: 16)),
                  onTap: () => _performSearch(term),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    onPressed: () => _deleteRecentSearch(term),
                  ),
                )).toList(),
              ),
            ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.trending_up, 
            iconColor: kNeedsFinePurple,
            title: '인기 검색어',
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _popularSearches.asMap().entries.map((entry) {
                int idx = entry.key;
                String term = entry.value;
                return ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text('${idx + 1}', style: const TextStyle(color: kNeedsFinePurple, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 6),
                       Text(term),
                    ],
                  ),
                  onPressed: () => _performSearch(term),
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF), // A light blue color
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 검색 팁', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('• 카테고리명으로 검색하면 해당 카테고리 맛집을 볼 수 있어요', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                Text('• 매장명을 검색하면 관련 매장과 비슷한 매장을 추천해드려요', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                Text('• 지역명과 함께 검색하면 더 정확한 결과를 얻을 수 있어요', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, Widget? action, required Widget child, Color? iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
