import 'package:flutter/material.dart';

class StepPassword extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String passwordValidationMessage;
  final String confirmPasswordMessage;

  const StepPassword({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordValidationMessage,
    required this.confirmPasswordMessage,
  });

  @override
  State<StepPassword> createState() => _StepPasswordState();
}

class _StepPasswordState extends State<StepPassword> {
  // 비밀번호 보임/숨김 상태 관리 변수
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    bool isPwValid = widget.passwordValidationMessage.contains('가능');
    bool isConfirmValid = widget.confirmPasswordMessage.contains('일치합니다');

    return Column(
      children: [
        // 1. 비밀번호 입력
        TextFormField(
          controller: widget.passwordController,
          obscureText: !_isPasswordVisible, // false면 보임, true면 숨김
          decoration: InputDecoration(
            labelText: '비밀번호',
            prefixIcon: const Icon(Icons.lock_outline),
            // [NEW] 눈 모양 아이콘 추가
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(widget.passwordValidationMessage, style: TextStyle(color: isPwValid ? Colors.green : Colors.grey, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 16),

        // 2. 비밀번호 확인
        TextFormField(
          controller: widget.confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible, // false면 보임, true면 숨김
          decoration: InputDecoration(
            labelText: '비밀번호 확인',
            prefixIcon: const Icon(Icons.check_circle_outline),
            // [NEW] 눈 모양 아이콘 추가
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(widget.confirmPasswordMessage, style: TextStyle(color: isConfirmValid ? Colors.green : Colors.red, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}