import 'package:flutter/material.dart';
// 각 탭에 들어갈 화면들 import
import 'home_screen.dart';
import 'nearby_screen.dart';
import 'user_mypage_screen.dart'; // 마이파인
import 'sanctuary_screen.dart';   // 성지
import 'menu_screen.dart';        // 메뉴
import 'under_construction_screen.dart'; // 홈, 내 위치 (임시 연결)

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // 탭별 화면 리스트
  final List<Widget> _screens = [
    const HomeScreen(),       // 0: 홈 (아직 없으면 공사중)
    const MenuScreen(),                                 // 1: 메뉴 (아이콘 격자)
    const NearbyScreen(),    // 2: 내 위치 (아직 없으면 공사중)
    const SanctuaryScreen(),                            // 3: 성지 (리스트)
    const UserMyPageScreen(),                           // 4: 마이파인
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // 선택된 화면 보여주기
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 탭이 4개 이상일 때 필수
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '메뉴'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '내 위치'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: '성지'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이파인'),
        ],
      ),
    );
  }
}