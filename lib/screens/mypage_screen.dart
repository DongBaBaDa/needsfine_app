import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // For the global 'isLoggedIn'
import 'package:needsfine_app/screens/mypage_logged_out.dart';
import 'package:needsfine_app/screens/user_mypage_screen.dart';

// --- [ ✅ ✅ 4-1. '마이페이지' ('로그인' '전후' '분기') ] ---
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // '전역' '상태'('isLoggedIn')를 '감지'하여 '화면' '전환'
    return ValueListenableBuilder<bool>(
      valueListenable: isLoggedIn, // [!] main.dart의 전역 변수 참조
      builder: (context, loggedIn, child) {
        if (loggedIn) {
          // '5-1' '요청' '사항' ('로그인' '후' '개인' '마이페이지')
          return const UserMyPageScreen();
        } else {
          // '4-1' '요청' '사항' ('로그인' '전' '마이페이지')
          return const MyPageLoggedOut();
        }
      },
    );
  }
}