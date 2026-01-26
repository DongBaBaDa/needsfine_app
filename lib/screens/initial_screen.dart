import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/signup/user_join_screen.dart';
import 'package:needsfine_app/screens/main_shell.dart';
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
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _navigateIfProfileCompleted(session.user.id);
    }
  }

  Future<void> _navigateIfProfileCompleted(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('nickname')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (profile != null && profile['nickname'] != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainShell()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("프로필 확인 중 에러: $e");
    }
  }

  // --- 소셜 로그인 함수들 (임시) ---
  Future<void> _signInWithNaver() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('네이버 로그인 준비 중')));
  }
  Future<void> _signInWithKakao() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카카오 로그인 준비 중')));
  }
  Future<void> _signInWithGoogle() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('구글 로그인 준비 중')));
  }
  Future<void> _signInWithApple() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('애플 로그인 준비 중')));
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
                // 로고 이미지
                Image.asset(
                  'assets/images/icon.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 100, color: Colors.grey);
                  },
                ),
                const SizedBox(height: 16),

                const Text('니즈파인',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: kNeedsFinePurple)),
                const Text('진짜가 필요해',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        letterSpacing: 1.2)),

                const SizedBox(height: 80),

                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("SNS 계정으로 시작하기",
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                  ],
                ),

                const SizedBox(height: 30),

                // ✅ 4. 소셜 로그인 버튼들 (모두 동일한 함수 사용)
                // 주의: google_g_logo.png와 apple_login.png도
                // 네이버/카카오처럼 "완성된 버튼 이미지"로 교체해야 자연스럽습니다.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                        'assets/images/naver_login.png',
                        _signInWithNaver
                    ),
                    const SizedBox(width: 20),

                    _buildSocialButton(
                        'assets/images/kakao_logo.png',
                        _signInWithKakao
                    ),
                    const SizedBox(width: 20),

                    _buildSocialButton(
                      'assets/images/google_g_logo.png', // 완성된 버튼 이미지 필요
                      _signInWithGoogle,
                    ),
                    const SizedBox(width: 20),

                    _buildSocialButton(
                      'assets/images/apple_login.png', // 완성된 버튼 이미지 필요
                      _signInWithApple,
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // 이메일 로그인 / 회원가입
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이메일로 가입하셨나요?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                        ).then((_) => _checkLoginStatus());
                      },
                      child: const Text('로그인하기',
                          style: TextStyle(fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserJoinScreen()),
                    ).then((_) => _checkLoginStatus());
                  },
                  child: const Text('이메일로 회원가입하기',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 통일된 소셜 버튼 빌더 함수
  // 모든 이미지를 버튼 크기에 맞춰 꽉 채웁니다 (BoxFit.cover).
  Widget _buildSocialButton(String assetName, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ClipOval로 이미지를 원형으로 자르고, cover로 꽉 채움
        child: ClipOval(
          child: Image.asset(
            assetName,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey[200], child: const Icon(Icons.error, color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}