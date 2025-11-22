import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // Reverted import

class UserJoinScreen extends StatefulWidget {
  const UserJoinScreen({super.key});

  @override
  State<UserJoinScreen> createState() => _UserJoinScreenState();
}

class _UserJoinScreenState extends State<UserJoinScreen> {

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("회원가입이 완료되었습니다.")),
    );
    isLoggedIn.value = true;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("일반 회원가입")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle("필수 정보"),
          const TextField(decoration: InputDecoration(labelText: "아이디 (영문, 숫자 포함 6-12자)")),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "비밀번호 (영문, 숫자, 특수문자 포함 8자 이상)")),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "비밀번호 확인")),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "닉네임")),
          const SizedBox(height: 32),

          _buildSectionTitle("선택 정보"),
          const TextField(decoration: InputDecoration(labelText: "이름")),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "이메일")),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "생년월일")),
          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
            child: const Text("가입 완료"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
