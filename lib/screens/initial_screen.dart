import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/user_join_screen.dart';
import 'package:needsfine_app/screens/email_pw_find_screen.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 로그인 상태 변화 감지
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

  // --- PASS 본인확인 관련 함수(_startPassVerification, _handleVerificationSuccess) 삭제 완료 ---

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('카카오 로그인 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 브랜드 로고 및 타이틀
                Image.asset('assets/icon.png', height: 100),
                const SizedBox(height: 16),
                const Text('니즈파인', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
                const Text('진짜가 필요해', style: TextStyle(fontSize: 16, color: Colors.grey, letterSpacing: 1.2)),

                // PASS 본인인증 버튼이 있던 자리의 간격을 조정합니다.
                const SizedBox(height: 80),

                // 2. 간편 로그인 섹션 시작
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("간편 로그인", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. 소셜 로그인 섹션
                _buildSocialButton(
                  onPressed: _signInWithKakao,
                  label: '카카오로 시작하기',
                  color: const Color(0xFFFEE500),
                  textColor: const Color(0xFF191919),
                  icon: Icons.chat_bubble,
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  onPressed: () {},
                  label: 'Google로 시작하기',
                  color: Colors.white,
                  textColor: Colors.black87,
                  icon: Icons.g_mobiledata,
                  hasBorder: true,
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  onPressed: () {},
                  label: 'Apple로 시작하기',
                  color: Colors.black,
                  textColor: Colors.white,
                  icon: Icons.apple,
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이메일로 가입하셨나요?', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserJoinScreen())),
                      child: const Text('로그인하기', style: TextStyle(fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
    required Color textColor,
    required IconData icon,
    bool hasBorder = false,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasBorder ? const BorderSide(color: Color(0xFFEEEEEE)) : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}