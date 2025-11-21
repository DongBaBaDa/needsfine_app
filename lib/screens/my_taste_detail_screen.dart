import 'package:flutter/material.dart';

class MyTasteDetailScreen extends StatelessWidget {
  const MyTasteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("다음 단계")),
      body: const Center(
        child: Text(
          "AI 맞춤 추천 기능이 추가될 예정입니다.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}