import 'package:flutter/material.dart';

class UnderConstructionScreen extends StatelessWidget {
  final String? title; // 화면 제목 (선택사항)

  const UnderConstructionScreen({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? "준비 중"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "현재 개발 진행 중인 화면입니다!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "조금만 기다려 주세요 뚝딱뚝딱 🛠️",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("돌아가기"),
            ),
          ],
        ),
      ),
    );
  }
}