import 'package:flutter/material.dart';

// --- [ ✅ ✅ 3-3. '검색' '화면' ] ---
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: "'홀' '점수', '배달' '점수' '따로' '검색'...",
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          ),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("실시간 검색 순위", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          for (int i = 1; i <= 9; i++)
            ListTile(
              leading: Text("$i", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              title: Text("'검색어' '순위' $i"),
            ),
        ],
      ),
    );
  }
}