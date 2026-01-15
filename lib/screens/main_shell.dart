import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // 테마 컬러 사용을 위해 추가

// ✅ 각 화면 파일 import
import 'package:needsfine_app/screens/feed_screen.dart';        // 1. 피드 (신규)
import 'package:needsfine_app/screens/ranking_screen.dart';     // 2. 리뷰 (기존)
import 'package:needsfine_app/screens/nearby_screen.dart';      // 3. 내 주변 (기존)
import 'package:needsfine_app/screens/store_screen.dart';       // 4. 가게 (신규)
// 기존 mypage_screen.dart 대신 관리자 기능이 포함된 최신 UserMyPageScreen을 사용합니다.
// 파일명이 다르다면 import 경로를 맞춰주세요.
import 'package:needsfine_app/screens/user_mypage_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // ✅ 5개의 화면 구성 (명령하신 순서대로 배치)
  final List<Widget> _widgetOptions = <Widget>[
    const FeedScreen(),       // 0: 피드
    const RankingScreen(),    // 1: 리뷰
    const NearbyScreen(),     // 2: 내 주변 (지도)
    const StoreScreen(),      // 3: 가게
    const UserMyPageScreen(), // 4: 마이파인
  ];

  @override
  void initState() {
    super.initState();
    // [유지] 전역 트리거 감시 리스너 등록
    searchTrigger.addListener(_onGlobalSearchTriggered);
  }

  @override
  void dispose() {
    // [유지] 리스너 해제
    searchTrigger.removeListener(_onGlobalSearchTriggered);
    super.dispose();
  }

  // [수정] 리뷰 화면에서 매장 클릭 시 '내 주변(지도)' 탭으로 이동
  void _onGlobalSearchTriggered() {
    if (searchTrigger.value != null && searchTrigger.value!.isNotEmpty) {
      if (mounted) {
        setState(() {
          // 🚨 중요: '내 주변' 탭이 3번째(인덱스 2)로 옮겨졌으므로 0 -> 2로 수정함
          _selectedIndex = 2;
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
      // [유지] IndexedStack을 사용하여 탭 전환 시 상태 유지
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // 1. 피드
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            activeIcon: Icon(Icons.dynamic_feed_outlined), // 선택됐을 때 아이콘 (필요시 변경)
            label: '피드',
          ),
          // 2. 리뷰 (기존 RankingScreen)
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: '리뷰',
          ),
          // 3. 내 주변 (기존 NearbyScreen)
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: '내 주변',
          ),
          // 4. 가게 (신규)
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: '가게',
          ),
          // 5. 마이파인 (UserMyPageScreen)
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '마이파인',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // 5개 탭이므로 fixed 필수
        selectedItemColor: const Color(0xFF9C7CFF), // 니즈파인 포인트 컬러
        unselectedItemColor: Colors.grey, // 선택 안 된 아이콘 색상
        showUnselectedLabels: true, // 라벨 항상 표시
      ),
    );
  }
}