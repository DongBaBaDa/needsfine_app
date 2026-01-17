import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // 테마 컬러

// ✅ 실제 화면 파일들 (너의 기존 Import 유지)
import 'package:needsfine_app/screens/feed_screen.dart';
import 'package:needsfine_app/screens/ranking_screen.dart';
import 'package:needsfine_app/screens/nearby_screen.dart';
import 'package:needsfine_app/screens/store_screen.dart';
import 'package:needsfine_app/screens/user_mypage_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 앱 시작 시 '내 주변(지도)' 탭을 기본으로 보여줄지, '피드'를 보여줄지 결정.
  // 기획상 '내 주변'이 핵심이라면 2, 아니라면 0. 일단 너의 설정인 0으로 둔다.
  int _selectedIndex = 0;

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

  // [유지] 리뷰 화면에서 매장 클릭 시 '내 주변(지도)' 탭으로 이동
  void _onGlobalSearchTriggered() {
    if (searchTrigger.value != null && searchTrigger.value!.isNotEmpty) {
      if (mounted) {
        setState(() {
          // '내 주변' 탭 인덱스인 2로 이동
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
    // 테마 컬러 참조 (없다면 직접 Color(0xFFC87CFF) 사용)
    const Color primaryColor = Color(0xFFC87CFF);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9), // Warm White 배경

      // [유지] 화면 상태 보존
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      // [Visual Silence] 하단 네비게이션 디자인 수정
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2), // 아주 얇은 경계선
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white, // 순수 흰색
          elevation: 0, // ⭐️ 그림자 제거 (핵심)

          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey[400],

          // 폰트 스타일 지정 (작고 깔끔하게)
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'NotoSansKR',
          ),

          items: const [
            // 1. 피드
            BottomNavigationBarItem(
              icon: Icon(Icons.dynamic_feed_rounded), // 둥근 아이콘
              label: '피드',
            ),
            // 2. 리뷰
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_rounded),
              label: '리뷰',
            ),
            // 3. 내 주변 (Center)
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_rounded),
              label: '내 주변',
            ),
            // 4. 가게
            BottomNavigationBarItem(
              icon: Icon(Icons.store_mall_directory_rounded),
              label: '가게',
            ),
            // 5. 마이파인
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: '마이파인',
            ),
          ],
        ),
      ),
    );
  }
}