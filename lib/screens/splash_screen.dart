import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase import 필수
import 'package:needsfine_app/screens/initial_screen.dart';
import 'package:needsfine_app/screens/main_shell.dart'; // 메인 화면(홈) import 필요

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 로그인 상태와 프로필 완성 여부를 체크하는 핵심 로직
  Future<void> _checkLoginStatus() async {
    // 1. 최소 2초는 로고를 보여줌 (UX)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    // 2. 로그인 세션이 있는지 확인
    if (session != null) {
      try {
        // 3. 세션이 있다면, '닉네임'이 설정되었는지 DB 확인
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('nickname')
            .eq('id', session.user.id)
            .maybeSingle();

        if (!mounted) return;

        // 4. 닉네임이 있으면 -> 가입 완료된 '진짜 유저' -> 홈으로 이동
        if (profile != null && profile['nickname'] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainShell()),
          );
          return;
        }
      } catch (e) {
        // DB 조회 중 에러나면 안전하게 초기 화면으로
        print('프로필 확인 중 에러: $e');
      }
    }

    // 5. 로그인 안 되어 있거나, 닉네임이 없으면(가입 중) -> 초기 화면으로 이동
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InitialScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 로고
            Image.asset(
              'assets/icon.png',
              width: 150,
            ),
            const SizedBox(height: 32),

            // 2. 니즈파인
            const Text(
              '니즈파인',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // 3. 진짜가 필요해
            const Text(
              '진짜가 필요해',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 4. 경험과 데이터가 만나는 곳
            const Text(
              '경험과 데이터가 만나는 곳',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}