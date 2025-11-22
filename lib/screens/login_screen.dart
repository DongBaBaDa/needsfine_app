import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // Reverted import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_idController.text == "user" && _pwController.text == "1234") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 되었습니다.")),
      );
      isLoggedIn.value = true;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("로그인 실패"),
          content: const Text("아이디 또는 비밀번호가 일치하지 않습니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "NeedsFine.",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 60),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: "아이디"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _onLogin,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
              child: const Text("로그인"),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/join-select'),
                  child: const Text("회원가입"),
                ),
                const Text("|"),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/find-account'),
                  child: const Text("계정찾기"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
