import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/home_screen.dart';
import 'package:needsfine_app/screens/ranking_screen.dart';
import 'package:needsfine_app/screens/nearby_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // [수정] 시작 페이지를 '내 주변'(지도)으로 설정
  int _selectedIndex = 0;

  // [수정] 3개의 페이지만 사용
  final List<Widget> _pages = const [
    NearbyScreen(),      // 0: 내 주변 (지도)
    RankingScreen(),     // 1: 랭킹
    HomeScreen(),        // 2: 홈
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // [수정] 3개의 탭 아이템만 표시
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "내 주변"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), label: "랭킹"),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "홈"),
        ],
      ),
    );
  }
}
