import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // For the global 'isLoggedIn'

// '매장' '회원가입' '완료' '시' '이동'
class StoreMyPageScreen extends StatelessWidget {
  const StoreMyPageScreen({super.key});
  @override
  Widget build(BuildContext context) { // 오타 수정됨
    return Scaffold(
      appBar: AppBar(title: const Text("매장 마이페이지")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("매장 마이페이지 (개발 중)"),
            ElevatedButton(
              onPressed: () {
                isLoggedIn.value = false; // [!] main.dart의 전역 변수 참조
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text("로그아웃 (테스트용)"),
            )
          ],
        ),
      ),
    );
  }
}