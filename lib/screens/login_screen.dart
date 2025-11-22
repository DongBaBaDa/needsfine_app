import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

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
      isLoggedIn.value = true;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("로그인 실패"),
          content: const Text("아이디 또는 비밀번호가 일치하지 않습니다."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인")),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "NeedsFine",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kNeedsFinePurple, fontFamily: 'GmarketSans'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                "사람의 경험과 데이터의 검증이 만나는 곳",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeedsFinePurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("로그인", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () {}, child: const Text("아이디 찾기", style: TextStyle(color: Colors.grey))),
                const Text(" | ", style: TextStyle(color: Colors.grey)),
                TextButton(onPressed: () {}, child: const Text("비밀번호 찾기", style: TextStyle(color: Colors.grey))),
                const Text(" | ", style: TextStyle(color: Colors.grey)),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/join-select'), child: const Text("회원가입", style: TextStyle(color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("또는", style: TextStyle(color: Colors.grey))),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            _buildSocialLoginButton(image: 'assets/images/kakao_logo.png', text: '카카오로 로그인', color: const Color(0xFFFEE500), textColor: Colors.black87),
            const SizedBox(height: 12),
            _buildSocialLoginButton(image: 'assets/images/naver_logo.png', text: '네이버로 로그인', color: const Color(0xFF03C75A), textColor: Colors.white),
            const SizedBox(height: 12),
            _buildSocialLoginButton(image: 'assets/images/google_logo.png', text: 'Google로 로그인', color: Colors.white, textColor: Colors.black54, hasBorder: true),
            const SizedBox(height: 12),
            _buildSocialLoginButton(image: 'assets/images/apple_logo.png', text: 'Apple로 로그인', color: Colors.black, textColor: Colors.white),
            const SizedBox(height: 48),
            const Text(
              "계속 진행하시면 NeedsFine의 서비스 이용약관 및 개인정보 처리방침에 동의하는 것으로 간주됩니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
             const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({required String image, required String text, required Color color, required Color textColor, bool hasBorder = false}) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasBorder ? const BorderSide(color: Colors.grey) : BorderSide.none,
        ),
        elevation: 0,
      ),
      // The Row was replaced by a simple Text widget to ensure perfect centering.
      // The logo will be added back later.
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
