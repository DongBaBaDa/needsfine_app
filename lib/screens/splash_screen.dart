import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/initial_screen.dart';
import 'package:needsfine_app/screens/main_shell.dart';

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

  Future<void> _checkLoginStatus() async {
    // 1. 네이티브 화면 직후, 여기서 로고를 2초간 보여줌
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    // 2. 로그인 세션 및 닉네임 확인
    if (session != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('nickname')
            .eq('id', session.user.id)
            .maybeSingle();

        if (!mounted) return;

        if (profile != null && profile['nickname'] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainShell()),
          );
          return;
        }
      } catch (e) {
        print('프로필 확인 중 에러: $e');
      }
    }

    // 3. 비로그인 유저는 초기 화면으로
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
            Image.asset(
              'assets/icon.png',
              width: 150,
            ),
            const SizedBox(height: 32),
            const Text(
              '니즈파인',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '진짜가 필요해',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
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