import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 수정: 전역 변수 대신 Supabase 직접 참조
import 'package:needsfine_app/screens/mypage_logged_out.dart';
import 'package:needsfine_app/screens/user_mypage_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [시니어 팁] 전역 변수 대신 Supabase의 현재 세션 정보를 실시간으로 감시합니다.
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 세션 정보가 있으면 로그인된 상태로 간주
        final session = snapshot.data?.session;
        final bool loggedIn = session != null;

        if (loggedIn) {
          return const UserMyPageScreen();
        } else {
          return const MyPageLoggedOut();
        }
      },
    );
  }
}