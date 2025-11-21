import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // For the global 'isLoggedIn'

// --- [ ✅ ✅ 4-1-2-1. '매장' '회원가입' ] ---
class StoreJoinScreen extends StatefulWidget {
  const StoreJoinScreen({super.key});

  @override
  State<StoreJoinScreen> createState() => _StoreJoinScreenState();
}

class _StoreJoinScreenState extends State<StoreJoinScreen> {
  final _emailCertController = TextEditingController();

  void _sendCertCode() {
    _emailCertController.text = "1234";
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("더미 인증번호 [1234]가 발송되었습니다.")),
    );
  }

  void _searchAddress() {
    showDialog(
      context: context,
      builder: (ctx) => const AddressSearchPopup(),
    );
  }

  void _handleJoin() {
    isLoggedIn.value = true; // [!] main.dart의 전역 변수 참조
    Navigator.pushNamedAndRemoveUntil(context, '/store-mypage', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("매장 회원가입"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextFormField(decoration: const InputDecoration(labelText: "아이디")),
          TextFormField(decoration: const InputDecoration(labelText: "비밀번호"), obscureText: true),
          TextFormField(decoration: const InputDecoration(labelText: "비밀번호 확인"), obscureText: true),
          Row(
            children: [
              Expanded(child: TextFormField(decoration: const InputDecoration(labelText: "이메일"))),
              ElevatedButton(onPressed: _sendCertCode, child: const Text("인증번호 받기")),
            ],
          ),
          TextFormField(
            controller: _emailCertController,
            decoration: const InputDecoration(labelText: "인증번호 입력"),
          ),
          TextFormField(decoration: const InputDecoration(labelText: "매장 이름")),
          Row(
            children: [
              Expanded(child: TextFormField(
                  decoration: const InputDecoration(labelText: "매장 주소"),
                  readOnly: true
              )),
              IconButton(onPressed: _searchAddress, icon: const Icon(Icons.search)),
            ],
          ),
          TextFormField(decoration: const InputDecoration(labelText: "상세주소")),
          TextFormField(decoration: const InputDecoration(labelText: "전화번호")),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _handleJoin,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text("회원가입"),
          ),
        ],
      ),
    );
  }
}

// '주소' '검색' '팝업' ('더미')
class AddressSearchPopup extends StatelessWidget {
  const AddressSearchPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("주소 검색"),
      content: const Text("('Daum' '주소' 'API' '연동' '필요')"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("닫기")),
      ],
    );
  }
}