import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
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

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    
    // ✅ 앱 링크(Deep Link)로 돌아왔을 때 인증 상태 변경을 감지하고 화면을 전환합니다.
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      // signedIn 이벤트 발생 시 (OAuth 로그인 성공 후 돌아왔을 때)
      if (event == AuthChangeEvent.signedIn && session != null) {
        _navigateIfProfileCompleted(session.user.id);
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
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

      if (profile != null && profile['nickname'] != null && profile['nickname'].toString().isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else {
        // 프로필 미완성 시 (또는 닉네임이 없을 시) 회원가입(약관, 닉네임 등) 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UserJoinScreen()),
        );
      }
    } catch (e) {
      debugPrint("프로필 확인 중 에러: $e");
      // 에러 시에도 기본적으로 회원가입으로 넘겨서 정보 완성 유도
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserJoinScreen()),
      );
    }
  }

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
          redirectTo: 'needsfine://login-callback',
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        // 구글 클라우드 콘솔의 '웹 애플리케이션' 클라이언트 ID 하드코딩
        serverClientId: '197198961843-u83rfkl7a00v1hooskodgjv88ijrknhs.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      // 기존 로그인 세션을 지워 무조건 계정 선택 창이 뜨게 강제함
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth?.idToken != null) {
        final AuthResponse res = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth!.idToken!,
          accessToken: googleAuth.accessToken,
        );
        if (res.user != null && mounted) _navigateIfProfileCompleted(res.user!.id);
      } else {
         // Fallback to web OAuth if native Google Sign-In isn't fully configured
         await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'needsfine://login-callback',
        );
      }
    } catch (e) {
      _showError('구글 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      // ✅ 현재 폰에서 사용 중인 카카오 키 해시를 콘솔에 출력 (디버깅용)
      try {
        final String origin = await KakaoSdk.origin;
        print("💡 [디버깅] 현재 기기의 카카오 키 해시: $origin");
      } catch (e) {
        print("💡 [디버깅] 키 해시 확인 실패: $e");
      }

      // 1. 카카오톡 실행 가능 여부 확인 후 카카오 로그인 시도
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인 시도
          token = await UserApi.instance.loginWithKakaoAccount(prompts: [Prompt.login]);
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount(prompts: [Prompt.login]);
      }

      // 2. 발급받은 token.idToken 으로 Supabase 인증 시도 
      if (token.idToken != null) {
        final AuthResponse res = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.kakao,
          idToken: token.idToken!,
        );
        if (res.user != null && mounted) _navigateIfProfileCompleted(res.user!.id);
      } else {
         // Fallback OIDC if native token lacks idToken
         await _supabase.auth.signInWithOAuth(
          OAuthProvider.kakao,
          redirectTo: 'needsfine://login-callback',
        );
      }
    } catch (e) {
      _showError('카카오 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                    // 🔓 소셜 로그인 UI 임시 비활성화 (애플 콘솔 설정 완료 전까지)
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

// 소셜 버튼 위젯
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
          child: Container(
            color: Colors.white, // Ensure white background for Apple/Google
            child: Image.asset(
              assetName,
              fit: BoxFit.fill, // fill or contain
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey[200], child: const Icon(Icons.error, color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }
}