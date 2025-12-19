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
  bool _showSearchResults = false;

  // Dummy data 
  final List<String> _popularSearches = ['데이트 맛집', '회식 장소', '혼밥 추천', '한식 뷔페'];
  List<String> _recentSearches = ['강남역 맛집', '압구정 카페', '홍대 술집'];
  final List<Map<String, dynamic>> _suggestedSearches = [
    {'type': 'related', 'text': '흑백요리사 시즌2 식당', 'icon': Icons.restaurant_menu},
    {'type': 'history', 'text': '성남뒷길', 'icon': Icons.history},
    {'type': 'location', 'text': '성남동 34', 'subtext': '경기도 성남시 중원구', 'icon': Icons.location_on_outlined},
    {'type': 'location', 'text': '성남동 2', 'subtext': '강원특별자치도 강릉시', 'icon': Icons.location_on_outlined},
    {'type': 'location', 'text': '성남동 1', 'subtext': '울산광역시 중구', 'icon': Icons.location_on_outlined},
    {'type': 'search', 'text': '성남시 분당/성남시 판교/성남 돌짜장', 'icon': Icons.search},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _searchController.addListener(() {
      setState(() {
        _showSearchResults = _searchController.text.isNotEmpty;
      });
    });
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
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
      // Navigator.pushNamed(context, '/search-result', arguments: query.trim());
      print("Searching for: ${query.trim()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "검색어를 입력하세요",
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          ),
          onSubmitted: _performSearch,
        ),
      ),
      body: _showSearchResults ? _buildSuggestionList() : _buildInitialScreen(),
    );
  }

  Widget _buildInitialScreen() {
    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (_recentSearches.isNotEmpty)
            _buildSection(
              title: '최근 검색어',
              action: TextButton(onPressed: () => setState(() => _recentSearches.clear()), child: const Text('전체 삭제')),
              child: Column(
                children: _recentSearches.map((term) => ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(term),
                  onTap: () => _performSearch(term),
                  trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _recentSearches.remove(term))),
                )).toList(),
              ),
            ),
          const SizedBox(height: 24),
          _buildSection(
            title: '인기 검색어',
            child: Wrap(
              spacing: 8.0,
              children: _popularSearches.map((term) => ActionChip(label: Text(term), onPressed: () => _performSearch(term))).toList(),
            ),
          ),
        ],
      );
  }

  Widget _buildSuggestionList() {
    return ListView.builder(
      itemCount: _suggestedSearches.length,
      itemBuilder: (context, index) {
        final item = _suggestedSearches[index];
        switch (item['type']) {
          case 'related':
            return ListTile(
              leading: const CircleAvatar(backgroundImage: NetworkImage('https://via.placeholder.com/150')), // Replace with actual image
              title: Text(item['text']),
              subtitle: const Text('식당'),
              trailing: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
            );
          case 'history':
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(item['text']),
              trailing: const Icon(Icons.north_west, color: Colors.grey),
            );
          case 'location':
            return ListTile(
              leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
              title: Text(item['text']),
              subtitle: Text(item['subtext']),
            );
          case 'search':
            return ListTile(
              leading: const Icon(Icons.search, color: Colors.grey),
              title: Text(item['text']),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildSection({required String title, Widget? action, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
