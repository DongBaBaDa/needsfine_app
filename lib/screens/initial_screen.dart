import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/user_join_screen.dart'; // 회원가입 화면
import 'package:needsfine_app/screens/login_screen.dart'; // 일반 로그인 화면

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 로고 이미지
              Image.asset('assets/icon.png', height: 150),
              const SizedBox(height: 60),

              // [수정] 일반 회원 로그인 버튼 -> 회원가입/로그인 화면으로 통합
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserJoinScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C7CFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                child: const Text('이메일로 시작하기', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // [추가] 소셜 로그인 버튼 영역
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('SNS 계정으로 시작하기')), Expanded(child: Divider())]),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TODO: 각 소셜 로그인 기능 연결
                  _buildSocialLoginButton('assets/images/kakao_icon.png', () {}),
                  const SizedBox(width: 24),
                  _buildSocialLoginButton('assets/images/naver_icon.png', () {}),
                  const SizedBox(width: 24),
                  _buildSocialLoginButton('assets/images/google_icon.png', () {}),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton(String assetPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(assetPath, width: 50, height: 50),
    );
  }
}
