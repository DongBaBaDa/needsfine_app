import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 이메일 로그인 처리 함수
  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Supabase 로그인 시도
      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ [중요] 유저 세션이 실제로 존재하는지 엄격하게 검증 (가짜 로그인 방지)
      if (res.user == null || res.session == null) {
        throw AuthException(l10n.loginInfoError);
      }

      // 2. 로그인 성공 시 즉시 홈 화면으로 강제 이동
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }

    } on AuthException catch (error) {
      // ✅ 인증 에러(없는 계정, 틀린 비번 등)를 구체적으로 출력
      if (mounted) {
        String message = l10n.loginInfoError;
        if (error.message.contains('Invalid login credentials')) {
          message = l10n.invalidCredentials;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );      }
    } catch (e) {
      // 일반 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.serverError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.emailLogin,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  l10n.welcomeBack,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 40),

                // 이메일 입력창
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailAddress,
                    hintText: l10n.emailPlaceholder,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kNeedsFinePurple, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력창
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kNeedsFinePurple, width: 2),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),

                // 로그인하기 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeedsFinePurple,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    l10n.loginButton,
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
