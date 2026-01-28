import 'package:flutter/material.dart';

class StepEmail extends StatefulWidget {
  final TextEditingController emailController;
  final VoidCallback onNext; // 다음 단계로 이동하는 함수

  const StepEmail({
    super.key,
    required this.emailController,
    required this.onNext,
  });

  @override
  State<StepEmail> createState() => _StepEmailState();
}

class _StepEmailState extends State<StepEmail> {
  bool _isNextEnabled = false;

  @override
  void initState() {
    super.initState();
    // 초기 상태 체크
    _checkInput();
    // 입력할 때마다 상태 체크
    widget.emailController.addListener(_checkInput);
  }

  @override
  void dispose() {
    widget.emailController.removeListener(_checkInput);
    super.dispose();
  }

  // 이메일 형식 체크 로직
  void _checkInput() {
    final text = widget.emailController.text;
    final isEnabled = text.contains('@') && text.contains('.');

    if (_isNextEnabled != isEnabled) {
      setState(() {
        _isNextEnabled = isEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이메일을 입력해주세요.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '로그인 및 계정 찾기에 사용됩니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // 이메일 입력 필드
          TextFormField(
            controller: widget.emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'example@email.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
              helperText: '인증 과정 없이 바로 진행됩니다.', // 안내 문구
            ),
            keyboardType: TextInputType.emailAddress,
          ),

          const Spacer(),

          // [다음] 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              // 이메일 형식이 맞으면(onNext) 실행, 아니면 null(비활성화)
              onPressed: _isNextEnabled ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}