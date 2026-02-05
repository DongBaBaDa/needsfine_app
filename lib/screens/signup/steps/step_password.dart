import 'package:flutter/material.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class StepPassword extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String pwMessage;
  final String confirmMessage;
  final VoidCallback onNext;
  final bool isPasswordValid;
  final bool isConfirmValid;

  const StepPassword({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.pwMessage,
    required this.confirmMessage,
    required this.onNext,
    required this.isPasswordValid,
    required this.isConfirmValid,
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

  @override
  void didUpdateWidget(covariant StepPassword oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 부모에서 유효성 플래그가 변경되면 버튼 상태 재확인
    if (oldWidget.isPasswordValid != widget.isPasswordValid ||
        oldWidget.isConfirmValid != widget.isConfirmValid) {
      _checkInput();
    }
  }

  void _checkInput() {
    final pw = widget.passwordController.text;
    final confirm = widget.confirmController.text;

    // 조건: 부모에서 전달받은 유효성 플래그 확인
    final isEnabled = widget.isPasswordValid &&
        widget.isConfirmValid &&
        pw.isNotEmpty && confirm.isNotEmpty;

    if (_isNextEnabled != isEnabled) {
      setState(() {
        _isNextEnabled = isEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(AppLocalizations.of(context)!.setPassword, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.passwordHint, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 40),

                    // 비밀번호 입력
                    TextFormField(
                      controller: widget.passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                        hintText: AppLocalizations.of(context)!.enterPassword,
                        border: const OutlineInputBorder(),
                        errorText: widget.isPasswordValid ? null : (widget.pwMessage.isNotEmpty ? widget.pwMessage : null),
                        helperText: widget.isPasswordValid ? widget.pwMessage : null,
                        helperStyle: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 확인
                    TextFormField(
                      controller: widget.confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.confirmPassword,
                        hintText: AppLocalizations.of(context)!.reenterPassword,
                        border: const OutlineInputBorder(),
                        errorText: widget.isConfirmValid ? null : (widget.confirmMessage.isNotEmpty ? widget.confirmMessage : null),
                        helperText: widget.isConfirmValid ? widget.confirmMessage : null,
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
                        child: Text(AppLocalizations.of(context)!.next, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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