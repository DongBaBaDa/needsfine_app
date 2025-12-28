import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

// 이 파일이 이제 앱의 첫 화면(로그인/회원가입) 역할을 합니다.
class UserJoinScreen extends StatefulWidget {
  const UserJoinScreen({super.key});

  @override
  State<UserJoinScreen> createState() => _UserJoinScreenState();
}

class _UserJoinScreenState extends State<UserJoinScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSigningUp = false; // 회원가입 모드인지 로그인 모드인지
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  // 이메일/비밀번호 작업 (로그인 또는 회원가입)
  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSigningUp) {
        // 회원가입
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 성공! 확인 메일을 확인해주세요.')),
          );
          setState(() => _isSigningUp = false); // 로그인 모드로 전환
        }
      } else {
        // 로그인
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('알 수 없는 오류: $e'), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  // 카카오 소셜 로그인
  Future<void> _signInWithKakao() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'needsfine://login-callback',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('카카오 로그인 실패: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 비밀번호 재설정
  Future<void> _passwordReset() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 재설정'),
          content: TextField(controller: emailController, decoration: const InputDecoration(labelText: '가입한 이메일을 입력하세요')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
            FilledButton(
              onPressed: () async {
                try {
                  await _supabase.auth.resetPasswordForEmail(emailController.text.trim());
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호 재설정 메일을 발송했습니다.')));
                  }
                } on AuthException catch (e) {
                   if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('전송'),
            ),
          ],
        );
      },
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
                  // 1. 로고와 앱 이름
                  Image.asset('assets/icon.png', height: 80),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('니즈파인', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 60),

                  // 2. 이메일, 비밀번호 입력
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

                  // 3. 로그인 또는 회원가입 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuthForm,
                    style: ElevatedButton.styleFrom(backgroundColor: kNeedsFinePurple, foregroundColor: Colors.white, minimumSize: const Size(0, 52)),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(_isSigningUp ? '이메일로 회원가입' : '로그인', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  
                  // [수정] 이메일/비밀번호 찾기 (중앙 정렬)
                  Center(
                    child: TextButton(
                      onPressed: _passwordReset,
                      child: const Text("이메일/비밀번호 찾기", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  
                  // [수정] 카카오 로그인 버튼
                  GestureDetector(
                    onTap: _isLoading ? null : _signInWithKakao,
                    child: Image.asset('assets/images/kakaologin.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  
                  // 회원가입/로그인 모드 전환
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isSigningUp ? '이미 계정이 있으신가요?' : '계정이 없으신가요?', style: const TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => setState(() => _isSigningUp = !_isSigningUp),
                        child: Text(_isSigningUp ? '로그인' : '회원가입', style: const TextStyle(fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
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
