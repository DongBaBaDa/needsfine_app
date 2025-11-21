import 'dart:async'; // Timer, Duration 등 기본 기능
import 'package:flutter/material.dart'; // UI 기본 도구
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences

// --- [ ✅ ✅ 2. '초기' '화면' ('온보딩' '팝업') ] ---
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingPopup();
    });
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _setHidePopup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hideUntil = DateTime.now().add(const Duration(days: 7));
      prefs.setString('hideOnboardingUntil', hideUntil.toIso8601String());
    } catch(e) {
      print("SharedPreferences '저장' '오류': $e");
    }
    _goToHome();
  }

  void _showOnboardingPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("니즈파인 점수 설명"),
          content: const Text(
              "'AI 탐정'이 '가짜 5점'을 '박살'내고 '진짜' '점수'만 '보여줍니다'. "
                  "'홀' '점수'와 '배달' '점수'를 '분리'하여 '검증'하십시오. "
                  "( '더미' '텍스트' '입니다'. )"
          ),
          actions: [
            TextButton(
              onPressed: _setHidePopup,
              child: const Text("일주일간 보지 않기"),
            ),
            TextButton(
              onPressed: _goToHome,
              child: const Text("닫기"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
