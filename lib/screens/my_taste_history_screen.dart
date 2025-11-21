import 'package:flutter/material.dart';

class MyTasteHistoryScreen extends StatelessWidget {
  const MyTasteHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("주문 히스토리")),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("두루치기"),
            subtitle: Text("2024-01-01 / 결제완료"),
          ),
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("제육볶음"),
            subtitle: Text("2024-01-02 / 결제완료"),
          ),
          ListTile(
            leading: Icon(Icons.cancel, color: Colors.red),
            title: Text("초밥"),
            subtitle: Text("취소됨 — 카운팅 제외"),
          ),
        ],
      ),
    );
  }
}