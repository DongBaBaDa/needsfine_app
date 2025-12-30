import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/user_join_screen.dart';
import 'package:needsfine_app/screens/email_pw_find_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'needsfine://login-callback',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('카카오 로그인 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToFindScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailPWFindScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainShell()),
              (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 카카오 공식 색상 및 텍스트 색상 정의
    const kakaoYellow = Color(0xFFFEE500);
    const kakaoText = Color(0xFF191919);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icon.png', height: 80),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('니즈파인', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text('진짜가 필요해', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ),
                  const SizedBox(height: 60),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: '이메일'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || !value.contains('@')) ? '유효한 이메일을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    obscureText: true,
                    validator: (value) => (value == null || value.length < 6) ? '6자리 이상 입력해주세요' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C7CFF), foregroundColor: Colors.white, minimumSize: const Size(0, 52)),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _navigateToFindScreen,
                      child: const Text("이메일/비밀번호 찾기", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // --- [수정] 이미지 대신 Flutter 코드로 구현한 카카오 로그인 버튼 ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithKakao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kakaoYellow, // 카카오 노란색 배경
                      foregroundColor: kakaoText, // 카카오 짙은 갈색/검정 텍스트
                      minimumSize: const Size(double.infinity, 52), // 다른 버튼과 크기 통일
                      elevation: 0, // 이미지처럼 평평하게
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 둥근 모서리
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        // 카카오톡 말풍선과 가장 비슷한 기본 아이콘 사용
                        Icon(Icons.chat_bubble, color: kakaoText, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '카카오 로그인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kakaoText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // -------------------------------------------------------

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('계정이 없으신가요?', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserJoinScreen())),
                        child: const Text('회원가입', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C7CFF))),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}