import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/main_shell.dart';

class UserJoinScreen extends StatefulWidget {
  const UserJoinScreen({super.key});

  @override
  State<UserJoinScreen> createState() => _UserJoinScreenState();
}

class _UserJoinScreenState extends State<UserJoinScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  // 일반 이메일/비밀번호 회원가입
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 확인 메일을 확인해주세요.')),
        );
        // 로그인 화면으로 이동 또는 자동 로그인 처리
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: ${e.message}')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알 수 없는 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 소셜 로그인
  Future<void> _signInWithProvider(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        authScreenLaunchMode: LaunchMode.externalApplication,
        redirectTo: 'needsfine://login-callback',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // 일반 회원가입
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
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading ? const CircularProgressIndicator() : const Text('이메일로 회원가입'),
              ),
              const SizedBox(height: 40),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('또는')), Expanded(child: Divider())]),
              const SizedBox(height: 24),
              // 소셜 로그인 버튼
              ElevatedButton.icon(
                onPressed: () => _signInWithProvider(OAuthProvider.kakao),
                icon: const Icon(Icons.chat_bubble), // 카카오 아이콘
                label: const Text('카카오로 로그인'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
              ),
              const SizedBox(height: 12),
              // [수정] 네이버 로그인은 공식 지원하지 않으므로 임시 비활성화
              // ElevatedButton.icon(
              //   onPressed: () => _signInWithProvider(OAuthProvider.naver),
              //   icon: const Icon(Icons.check_circle, color: Colors.white), // 네이버 아이콘
              //   label: const Text('네이버로 로그인', style: TextStyle(color: Colors.white)),
              //   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              // ),
            ],
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
