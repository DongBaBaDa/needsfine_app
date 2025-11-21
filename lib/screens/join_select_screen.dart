import 'package:flutter/material.dart';

// --- [ ✅ ✅ 4-1-2. '회원가입' '선택' '화면' ] ---
class JoinSelectScreen extends StatelessWidget {
  const JoinSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입 유형 선택")),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // 오타 수정됨
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/join-store'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 60)),
              child: const Text("매장 회원가입"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/join-user'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 60)),
              child: const Text("개인 회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}