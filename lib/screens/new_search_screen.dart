import 'dart:async'; // [추가] Timer 사용을 위해 필요

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewSearchScreen extends StatefulWidget {
  const NewSearchScreen({super.key});

  @override
  State<NewSearchScreen> createState() => _NewSearchScreenState();
}

class _NewSearchScreenState extends State<NewSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  Timer? _debounce;

  // [추가] 네이버 API 인증 정보
  final String _clientId = '1rst5nv703'; 
  final String _clientSecret = 'FTC0ifJsvXdQQOI91bzqFbIhZ8pZUWAKb3MToqsW';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(_searchController.text);
    });
  }

  // [추가] 네이버 Geocoding API 호출 로직
  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    try {
      final url = Uri.parse('https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=$query');
      final response = await http.get(url, headers: {
        'X-NCP-APIGW-API-KEY-ID': _clientId,
        'X-NCP-APIGW-API-KEY': _clientSecret,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['addresses'] != null) {
          final addresses = (data['addresses'] as List)
              .map((addr) => addr['roadAddress'] as String?)
              .where((addr) => addr != null)
              .take(10)
              .toList();
          setState(() {
            _suggestions = addresses.cast<String>();
          });
        }
      } else {
        print("Geocoding API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Search suggestion error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '국내마사지'), Tab(text: '베트남마사지')],
            labelColor: Colors.black,
            indicatorColor: Colors.black,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '성남',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_suggestions[index]));
              },
            ),
          )
        ],
      ),
    );
  }
}
