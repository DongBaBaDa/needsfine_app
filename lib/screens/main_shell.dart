import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/nearby_screen.dart';
import 'package:needsfine_app/screens/ranking_screen.dart'; // [수정] 파일명 언더바 확인
import 'package:needsfine_app/screens/mypage_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // 3개의 화면 구성
  final List<Widget> _widgetOptions = <Widget>[
    const NearbyScreen(),
    const RankingScreen(),
    const MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // [추가] 전역 트리거 감시 리스너 등록
    // ranking_screen.dart에 선언된 searchTrigger를 사용합니다.
    searchTrigger.addListener(_onGlobalSearchTriggered);
  }

  @override
  void dispose() {
    // [추가] 리스너 해제 (메모리 누수 방지)
    searchTrigger.removeListener(_onGlobalSearchTriggered);
    super.dispose();
  }

  // 리뷰 화면에서 매장 클릭 시 호출되는 함수
  void _onGlobalSearchTriggered() {
    if (searchTrigger.value != null && searchTrigger.value!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedIndex = 0; // '내 주변'(지도) 탭인 0번 인덱스로 강제 이동
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack을 사용하여 탭 전환 시에도 지도나 리뷰 목록 상태가 초기화되지 않게 유지
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: '내 주변',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: '리뷰',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '마이파인',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9C7CFF), // 니즈파인 포인트 컬러
      ),
    );
  }
}