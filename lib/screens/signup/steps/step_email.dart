import 'package:flutter/material.dart';

class StepEmail extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController authCodeController;
  final bool isAuthCodeSent;
  final bool isEmailVerified;
  final bool isLoading;
  final VoidCallback onSendAuthCode;
  final VoidCallback onVerifyAuthCode;
  final int remainingTime; // [NEW] 타이머 시간

  const StepEmail({
    super.key,
    required this.emailController,
    required this.authCodeController,
    required this.isAuthCodeSent,
    required this.isEmailVerified,
    required this.isLoading,
    required this.onSendAuthCode,
    required this.onVerifyAuthCode,
    required this.remainingTime, // [NEW] 필수값 추가
  });

  String get _timerText {
    final minutes = (remainingTime / 60).floor();
    final seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: '이메일', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                enabled: !isEmailVerified,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              // 시간이 남아있거나(>0), 로딩중이거나, 이미 인증됐으면 버튼 비활성화
              onPressed: (isLoading || isEmailVerified || (remainingTime > 0 && isAuthCodeSent))
                  ? null
                  : onSendAuthCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: const Color(0xFF9C7CFF).withOpacity(0.1),
                elevation: 0,
              ),
              child: Text(
                (remainingTime > 0 && isAuthCodeSent) ? _timerText : '인증',
                style: const TextStyle(color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (isAuthCodeSent) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: authCodeController,
                  decoration: const InputDecoration(labelText: '인증번호 6자리', prefixIcon: Icon(Icons.lock_clock_outlined)),
                  keyboardType: TextInputType.number,
                  enabled: !isEmailVerified,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (isLoading || isEmailVerified || remainingTime == 0) ? null : onVerifyAuthCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C7CFF),
                ),
                child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (remainingTime == 0 && !isEmailVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('인증 시간이 만료되었습니다. 다시 인증 버튼을 눌러주세요.', style: TextStyle(color: Colors.red[400], fontSize: 12)),
            ),
        ]
      ],
    );
  }
}