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
        backgroundColor: Color(0xFF03C75A),
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

                // 네이버 로그인 버튼 (통이미지 방식)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _signInWithNaver,
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/naver_login.png',
                        width: double.infinity,
                        height: 54,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 카카오 로그인 버튼 (중앙 정렬)
                _buildSocialButton(
                  onPressed: _signInWithKakao,
                  label: '카카오 로그인',
                  color: const Color(0xFFFEE500),
                  textColor: const Color(0xFF191919),
                  iconWidget: Image.asset(
                    'assets/kakao_logo.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(height: 12),

                // 구글 로그인 버튼 (요청하신 보간 최적화 및 테두리 제거 적용)
                _buildSocialButton(
                  onPressed: _signInWithGoogle,
                  label: '구글로 로그인',
                  color: const Color(0xFFFFFFFF),
                  textColor: const Color(0xFF1F1F1F),
                  iconWidget: Image.asset(
                    'assets/google_g_logo.png',
                    width: 20, // 정수 크기 권장 반영
                    height: 20,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none, // 경계선(halo) 줄이기 반영
                    isAntiAlias: true,
                    gaplessPlayback: true,
                  ),
                  hasBorder: false, // 버튼 외곽선을 제거하여 로고 테두리와의 혼동 방지
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

  // 소셜 버튼 위젯
  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
    required Color textColor,
    required Widget iconWidget,
    bool hasBorder = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: hasBorder
              ? const BorderSide(color: Color(0xFFF2F2F2), width: 1.0)
              : BorderSide.none,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}