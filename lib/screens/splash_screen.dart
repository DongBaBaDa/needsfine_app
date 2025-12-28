import 'package:flutter/material.dart';
import 'dart:async';
import 'package:needsfine_app/screens/initial_screen.dart'; // [수정] 로그인/회원가입 첫 화면

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3), // 시간을 3초로 늘려 텍스트가 잘 보이도록 함
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InitialScreen()), // [수정] InitialScreen으로 이동
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 흰색 배경
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
