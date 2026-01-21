// lib/screens/main_shell.dart
import 'package:flutter/material.dart';

import 'package:needsfine_app/screens/home_screen.dart';
// ✅ [수정] 충돌 방지를 위해 별칭(alias) 사용
import 'package:needsfine_app/screens/ranking_screen.dart' as ranking;
import 'package:needsfine_app/screens/nearby_screen.dart';
import 'package:needsfine_app/screens/user_mypage_screen.dart';

// ✅ SearchTarget이 정의된 파일 임포트
import 'package:needsfine_app/core/search_trigger.dart';

// ✅ [추가] 다국어 패키지 임포트
import 'package:needsfine_app/l10n/app_localizations.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // ⚠️ [수정] l10n은 build context가 필요하므로 static/const 제거하고 build 메서드 내부나 getter로 이동
  // 화면 리스트는 상태 유지용이므로 그대로 둠
  final List<Widget> _widgetOptions = const <Widget>[
    HomeScreen(),                 // 0: 홈
    ranking.RankingScreen(),      // 1: 랭킹 (리뷰)
    NearbyScreen(),               // 2: 내 주변
    UserMyPageScreen(),           // 3: 마이파인
  ];

  @override
  void initState() {
    super.initState();
    searchTrigger.addListener(_onGlobalSearchTriggered);
  }

  @override
  void dispose() {
    searchTrigger.removeListener(_onGlobalSearchTriggered);
    super.dispose();
  }

  void _onGlobalSearchTriggered() {
    final target = searchTrigger.value;
    // ✅ [수정] SearchTarget 객체의 query 필드를 확인
    if (target != null && target.query.isNotEmpty) {
      if (mounted) {
        setState(() => _selectedIndex = 2); // 내 주변 탭으로 이동
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFC87CFF);
    // ✅ l10n 객체 가져오기
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey[400],
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
          // ✅ [수정] 라벨을 l10n 변수로 교체
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.home, // "홈"
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events_rounded),
              label: l10n.review, // "리뷰"
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.location_on_rounded),
              label: l10n.mySurroundings, // "내 주변"
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n.myFine, // "마이파인"
            ),
          ],
        ),
      ),
    );
  }
}