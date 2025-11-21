import 'package:flutter/material.dart';

// '개인' '마이페이지' - '아이콘 & 칭호'
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("아이콘 & 칭호"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(child: Text("아이콘 칭호 화면 (개발 중)")),
    );
  }
}