import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/user_join_screen.dart';
import 'package:needsfine_app/screens/email_login_screen.dart';
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

  // --- 소셜 로그인 로직 (준비 중) ---

  Future<void> _signInWithKakao() async {
    print("카카오 로그인은 준비 중입니다.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중입니다.')),
    );
  }

  Future<void> _signInWithGoogle() async {
    print("구글 로그인은 준비 중입니다.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중입니다.')),
    );
  }

  Future<void> _signInWithNaver() async {
    print("네이버 로그인은 준비 중입니다.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중입니다.')),
    );
  }

  void _handleError(String title, Object e) {
    debugPrint('$title: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: kNeedsFinePurple)
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon.png', height: 100),
                const SizedBox(height: 16),
                const Text('니즈파인', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
                const Text('진짜가 필요해', style: TextStyle(fontSize: 16, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 60),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("간편 로그인", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _isLoading ? null : _signInWithNaver,
                  child: Image.asset('assets/naver_login.png', width: double.infinity, height: 54, fit: BoxFit.fill),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _signInWithKakao,
                  child: Image.asset('assets/images/kakaologin.png', width: double.infinity, height: 54, fit: BoxFit.fill),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  onPressed: _signInWithGoogle,
                  label: '구글로 로그인',
                  color: const Color(0xFFFFFFFF),
                  textColor: const Color(0xFF1F1F1F),
                  iconWidget: Image.asset('assets/google_g_logo.png', width: 24),
                  borderColor: const Color(0xFF747775),
                  isPill: true,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이메일로 가입하셨나요?', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailLoginScreen())),
                      child: const Text('로그인하기', style: TextStyle(fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserJoinScreen())),
                  child: const Text('이메일로 회원가입하기', style: TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.underline)),
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
    required Widget iconWidget,
    Color? borderColor,
    bool isPill = false,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: isPill ? const StadiumBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: borderColor != null ? BorderSide(color: borderColor, width: 1.2) : BorderSide.none,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, child: iconWidget),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
