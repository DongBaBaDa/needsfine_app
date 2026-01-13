import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    // 로그인 상태 변화를 감지하여 세션이 있으면 메인 화면으로 이동
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

  // 카카오 로그인 로직
  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.kakao);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 구글 로그인 로직
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // GCP 콘솔에서 발급받은 'Web Client ID'를 입력하세요.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '197198961843-u83r...apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth?.idToken != null) {
        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth!.idToken!,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구글 로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 네이버 로그인 (준비 중 메시지)
  void _signInWithNaver() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('네이버 로그인은 준비 중입니다. (Coming soon)'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF03C75A), // 네이버 브랜드 컬러
      ),
    );
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
                const Text(
                  '니즈파인',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kNeedsFinePurple,
                  ),
                ),
                const Text(
                  '진짜가 필요해',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),

                // 2. 간편 로그인 섹션
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "간편 로그인",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // 네이버 로그인 (이미지 버튼)
                _buildImageButton(
                  onTap: _signInWithNaver,
                  imagePath: 'assets/naver_login.png',
                ),
                const SizedBox(height: 12),

                // 카카오 로그인 (이미지 버튼)
                _buildImageButton(
                  onTap: _signInWithKakao,
                  imagePath: 'assets/kakao_logo.png',
                ),
                const SizedBox(height: 12),

                // 구글 로그인 (로고 + "구글로 로그인" 텍스트 조합 알약 버튼)
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

                // 3. 하단 링크 섹션
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('이메일로 가입하셨나요?', style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                          ),
                          child: const Text(
                            '로그인하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kNeedsFinePurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserJoinScreen()),
                      ),
                      child: const Text(
                        '이메일로 회원가입하기',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

  // 이미지를 버튼으로 사용하는 위젯 (네이버, 카카오용)
  Widget _buildImageButton({required VoidCallback onTap, required String imagePath}) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        imagePath,
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  // 커스텀 소셜 버튼 위젯 (구글용)
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
        shape: isPill
            ? const StadiumBorder()
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 1.2)
            : BorderSide.none,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, child: iconWidget),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}