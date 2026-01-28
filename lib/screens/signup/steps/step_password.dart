import 'package:flutter/material.dart';

class StepPassword extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String pwMessage;
  final String confirmMessage;
  final VoidCallback onNext;

  const StepPassword({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.pwMessage,
    required this.confirmMessage,
    required this.onNext,
  });

  @override
  State<StepPassword> createState() => _StepPasswordState();
}

class _StepPasswordState extends State<StepPassword> {
  bool _isNextEnabled = false;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_checkInput);
    widget.confirmController.addListener(_checkInput);
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_checkInput);
    widget.confirmController.removeListener(_checkInput);
    super.dispose();
  }

  void _checkInput() {
    final pw = widget.passwordController.text;
    final confirm = widget.confirmController.text;

    // 조건: 비밀번호 유효성 메시지가 '가능'을 포함하고, 확인 메시지가 '일치'를 포함할 때
    final isEnabled = widget.pwMessage.contains('가능') &&
        widget.confirmMessage.contains('일치') &&
        pw.isNotEmpty && confirm.isNotEmpty;

    if (_isNextEnabled != isEnabled) {
      setState(() {
        _isNextEnabled = isEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // [핵심 수정] LayoutBuilder + SingleChildScrollView + IntrinsicHeight 조합
    // 키보드가 올라와도 에러 없이 스크롤되게 하고, 평소에는 버튼을 바닥에 붙입니다.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, // 최소 높이를 화면 전체로 잡음
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('비밀번호를 설정해주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('영문, 숫자, 특수문자 포함 8자 이상', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 40),

                    // 비밀번호 입력
                    TextFormField(
                      controller: widget.passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: '비밀번호 입력',
                        border: const OutlineInputBorder(),
                        errorText: widget.pwMessage.isEmpty || widget.pwMessage.contains('가능') ? null : widget.pwMessage,
                        helperText: widget.pwMessage.contains('가능') ? widget.pwMessage : null,
                        helperStyle: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 확인
                    TextFormField(
                      controller: widget.confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인',
                        hintText: '비밀번호 재입력',
                        border: const OutlineInputBorder(),
                        errorText: widget.confirmMessage.isEmpty || widget.confirmMessage.contains('일치합니다') ? null : widget.confirmMessage,
                        helperText: widget.confirmMessage.contains('일치합니다') ? widget.confirmMessage : null,
                        helperStyle: const TextStyle(color: Colors.blue),
                      ),
                    ),

                    const Spacer(), // 남는 공간을 차지하여 버튼을 아래로 밀어냄

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isNextEnabled ? widget.onNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    // 키보드에 딱 붙지 않게 약간의 여백 추가
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}