import 'package:flutter/material.dart';

class Store {
  final String name;
  final String category;
  final double needsFineScore;
  const Store({required this.name, required this.category, required this.needsFineScore});
}

class SearchResultScreen extends StatelessWidget {
  final String searchTerm;
  const SearchResultScreen({super.key, required this.searchTerm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('"$searchTerm" 검색 결과')),
      body: Center(child: Text('검색 결과가 여기에 표시됩니다.')),
    );
  }
}
