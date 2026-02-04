import 'dart:convert';
import 'dart:io';
// import 'package:crypto/crypto.dart'; // [심사 대비] 주석 처리
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // [심사 대비] 주석 처리
import 'package:needsfine_app/screens/signup/user_join_screen.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/email_login_screen.dart';
import 'package:needsfine_app/screens/language_settings_screen.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

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
      } else {
        // 프로필 미완성 시 처리 (필요시 구현)
      }
    } catch (e) {
      debugPrint("프로필 확인 중 에러: $e");
    }
  }

  // ------------------------------------------------------------------
  // 🔒 [심사 대비] 소셜 로그인 로직 전체 주석 처리
  // 나중에 기능을 완벽히 구현한 뒤 주석을 해제하세요.
  // ------------------------------------------------------------------
  /*
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isIOS) {
        // 🍎 1. iOS: 네이티브 로그인 (Nonce 사용)
        final rawNonce = _supabase.auth.generateRawNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        if (credential.identityToken == null) {
          throw const AuthException('Apple Identity Token이 없습니다.');
        }

        // Supabase 인증
        final AuthResponse res = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: credential.identityToken!,
          nonce: rawNonce,
        );

        if (res.user != null) {
          if (mounted) _navigateIfProfileCompleted(res.user!.id);
        }

      } else {
        // 🤖 2. Android: 웹 OAuth 방식 (Supabase 리다이렉트)
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: 'my-app-scheme://login-callback',
        );
      }
    } on AuthException catch (e) {
      _showError('인증 오류: ${e.message}');
    } catch (e) {
      _showError('로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithNaver() async {
    _showError('네이버 로그인 준비 중입니다.');
  }
  Future<void> _signInWithKakao() async {
    _showError('카카오 로그인 준비 중입니다.');
  }
  Future<void> _signInWithGoogle() async {
    _showError('구글 로그인 준비 중입니다.');
  }
  */

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 기존 화면 콘텐츠
          SafeArea(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: kNeedsFinePurple)
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고
                    Image.asset(
                      'assets/images/icon.png',
                      height: 100,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.error, size: 100, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    Text(l10n.appName,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: kNeedsFinePurple)),
                    Text(l10n.appTagline,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            letterSpacing: 1.2)),

                    const SizedBox(height: 120), // 중앙 공백 확보

                    // ------------------------------------------------
                    // 🔒 [심사 대비] 소셜 로그인 UI 숨김 (주석 처리)
                    // ------------------------------------------------
                    /*
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
                            'assets/images/google_g_logo.png',
                            _signInWithGoogle,
                          ),
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            'assets/images/apple_login.png',
                            _signInWithApple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      */
                    // ------------------------------------------------

                    // ✅ 이메일 로그인을 메인 버튼으로 변경 (심사 통과용 UI 개선)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                          ).then((_) => _checkLoginStatus());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kNeedsFinePurple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(l10n.emailLoginButton,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserJoinScreen()),
                        ).then((_) => _checkLoginStatus());
                      },
                      child: Text(l10n.emailSignupButton,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ✅ 우측 하단 언어 선택 버튼
          Positioned(
            right: 20,
            bottom: 50,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguageSettingsScreen(),
                  ),
                );
                if (mounted) setState(() {}); // 언어 변경 후 화면 갱신
              },
              child: const Icon(Icons.language, color: kNeedsFinePurple, size: 28),
            ),
          ),
        ],
      ),
    );
  }

// 소셜 버튼 위젯도 일단 주석 처리 (사용하지 않음 경고 방지)
/*
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
  */
}