import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // For the global 'isLoggedIn'

// --- [ ✅ ✅ 4-1-2-2. '개인' '회원가입' ] ---
class UserJoinScreen extends StatefulWidget {
  const UserJoinScreen({super.key});

  @override
  State<UserJoinScreen> createState() => _UserJoinScreenState();
}

class _UserJoinScreenState extends State<UserJoinScreen> {
  final _idController = TextEditingController();
  bool _isDuplicate = false;

  void _checkDuplicate() {
    final id = _idController.text;
    if (id == "admin" || id == "test") {
      setState(() { _isDuplicate = true; });
    } else {
      setState(() { _isDuplicate = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사용 가능한 아이디입니다.")),
      );
    }
  }

  void _handleJoin() {
    isLoggedIn.value = true; // [!] main.dart의 전역 변수 참조
    Navigator.pushNamedAndRemoveUntil(context, '/user-mypage', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("개인 회원가입"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: "아이디(닉네임)"),
                )),
                ElevatedButton(onPressed: _checkDuplicate, child: const Text("중복확인")),
              ],
            ),
            if (_isDuplicate)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "다른 닉네임을 사용하세요",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextFormField(decoration: const InputDecoration(labelText: "비밀번호"), obscureText: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleJoin,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}