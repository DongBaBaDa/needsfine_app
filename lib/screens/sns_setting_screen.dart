import 'package:flutter/material.dart';

class SnsSettingScreen extends StatefulWidget {
  const SnsSettingScreen({super.key});

  @override
  State<SnsSettingScreen> createState() => _SnsSettingScreenState();
}

class _SnsSettingScreenState extends State<SnsSettingScreen> {
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _blogController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SNS 설정'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 저장 로직은 추후 구현
            },
            child: const Text("저장", style: TextStyle(color: Colors.black)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("SNS 계정을 연결하여\n나를 더 잘 표현해보세요!", style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildSnsInput(
            icon: Icons.camera_alt_outlined, 
            label: '인스타그램', 
            hint: '아이디 입력', 
            controller: _instagramController
          ),
          const SizedBox(height: 16),
          _buildSnsInput(
            icon: Icons.play_circle_outline, 
            label: '유튜브', 
            hint: '채널 링크 입력', 
            controller: _youtubeController
          ),
          const SizedBox(height: 16),
          _buildSnsInput(
            icon: Icons.edit_note, 
            label: '블로그', 
            hint: '블로그 주소 입력', 
            controller: _blogController
          ),
        ],
      ),
    );
  }

  Widget _buildSnsInput({required IconData icon, required String label, required String hint, required TextEditingController controller}) {
    return Row(
      children: [
        Icon(icon, size: 30, color: Colors.grey[700]),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
