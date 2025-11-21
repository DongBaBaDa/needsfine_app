import 'dart:async'; // Timer 때문에 필요
import 'package:flutter/material.dart';
// [!] SharedPreferences는 이 파일에서 더 이상 필요 없으므로 제거했습니다.

// --- [ ✅ ✅ 1. '스플래시' '화면' (수정됨) ] ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 5), () {

      // [!] '/home'으로 바로 이동
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ [수정됨] const를 여기서 제거했습니다.
    // Text 위젯들이 const가 아니기 때문에 Scaffold도 const가 될 수 없습니다.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "NeedsFine.",
              style: TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16), // SizedBox는 const가 가능
            Text(
              "진짜가 필요해",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12), // SizedBox는 const가 가능
            Text(
              "사람의 경험과 데이터의 검증이 만나는 곳",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}