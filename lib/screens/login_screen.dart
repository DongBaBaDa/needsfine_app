import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:needsfine_app/main.dart'; // For the global 'isLoggedIn'

// --- [ ✅ ✅ 4-1-1. '로그인' '화면' ] ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(text: "test");
  final _pwController = TextEditingController(text: "1234");
  bool _autoLogin = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final id = _idController.text;
      final pw = _pwController.text;

      if (id != "test") {
        _showErrorPopup("가입되지 않은 아이디입니다.");
      } else if (pw != "1234") {
        _showErrorPopup("비밀번호가 일치하지 않습니다.");
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('autoLogin', _autoLogin);
        } catch(e) {
          print("SharedPreferences '저장' '오류': $e");
        }
        isLoggedIn.value = true; // [!] main.dart의 전역 변수 참조
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("로그인 실패"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("확인"),
          )
        ],
      ),
    );
  }

  void _showSnsPopup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SNS 로그인 연동 준비 중입니다.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("NeedsFine", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: "아이디"),
                  validator: (val) => val!.isEmpty ? "아이디를 입력하세요" : null,
                ),
                TextFormField(
                  controller: _pwController,
                  decoration: const InputDecoration(labelText: "비밀번호"),
                  obscureText: true,
                  validator: (val) => val!.isEmpty ? "비밀번호를 입력하세요" : null,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text("자동로그인"),
                  value: _autoLogin,
                  onChanged: (val) {
                    setState(() { _autoLogin = val!; });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text("로그인"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/join-select'),
                        child: const Text("회원가입")
                    ),
                    const Text("|"),
                    TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/find-account'),
                        child: const Text("아이디/비밀번호 찾기")
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _showSnsPopup, child: const Text("카카오 로그인")),
                ElevatedButton(onPressed: _showSnsPopup, child: const Text("구글 로그인")),
                ElevatedButton(onPressed: _showSnsPopup, child: const Text("네이버 로그인")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}