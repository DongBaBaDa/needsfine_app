import 'package:flutter/material.dart';

class MyTasteReportScreen extends StatelessWidget {
  const MyTasteReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("음식 성향 리포트")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text("🍜 한식 선호도: 85%", style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text("🍣 일식 선호도: 72%", style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text("🍔 패스트푸드 선호도: 64%", style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),
          Text("AI가 나의 맛 성향을 분석 중입니다…"),
        ],
      ),
    );
  }
}