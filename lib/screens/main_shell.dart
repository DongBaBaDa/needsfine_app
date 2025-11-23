import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/home_screen.dart';
import 'package:needsfine_app/screens/ranking_screen.dart';
import 'package:needsfine_app/screens/nearby_screen.dart';
import 'package:needsfine_app/screens/sanctuary_screen.dart';
import 'package:needsfine_app/screens/user_mypage_screen.dart';
import 'package:needsfine_app/main.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // indexedStack 구조 — 상태 유지
  final List<Widget> _pages = const [
    HomeScreen(),
    RankingScreen(),
    NearbyScreen(),
    SanctuaryScreen(),
    UserMyPageScreen(),
  ];

  void _onItemTapped(int index) {
    // 로그인 안 된 상태에서 마이파인 진입 방지
    if (index == 4 && !isLoggedIn.value) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 화면 부서짐 방지 — IndexedStack
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), label: "랭킹"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "내 주변"),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: "성지"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "마이파인"),
        ],
      ),
    );
  }
}
