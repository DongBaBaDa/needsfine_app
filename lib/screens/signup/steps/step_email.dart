import 'package:flutter/material.dart';

import 'package:needsfine_app/l10n/app_localizations.dart';

class StepEmail extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController authCodeController;
  final bool isAuthCodeSent;
  final bool isEmailVerified;
  final bool isLoading;
  final VoidCallback onSendTap;
  final VoidCallback onVerifyTap;
  final VoidCallback onNext;

  const StepEmail({
    super.key,
    required this.emailController,
    required this.authCodeController,
    required this.isAuthCodeSent,
    required this.isEmailVerified,
    required this.isLoading,
    required this.onSendTap,
    required this.onVerifyTap,
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
    // 가로모드에서도 스크롤 가능하도록 LayoutBuilder + SingleChildScrollView 사용
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.enterEmail,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.emailUsageInfo,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    // 이메일 입력 필드 & 전송 버튼
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.emailController,
                            enabled: !widget.isEmailVerified, // 인증 완료되면 수정 불가
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.emailAddress,
                              hintText: 'example@email.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (widget.isEmailVerified || widget.isLoading || !_isNextEnabled)
                                ? null
                                : widget.onSendTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text(widget.isAuthCodeSent ? AppLocalizations.of(context)!.resend : AppLocalizations.of(context)!.requestAuth),
                          ),
                        ),
                      ],
                    ),

                    // 인증번호 입력 필드 (전송된 경우에만 표시)
                    if (widget.isAuthCodeSent && !widget.isEmailVerified) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: widget.authCodeController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.authCode,
                                hintText: '123456',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: widget.isLoading ? null : widget.onVerifyTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8A2BE2),
                                foregroundColor: Colors.white, // 브랜드 컬러
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text(AppLocalizations.of(context)!.confirm),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // 인증 완료 메시지
                    if (widget.isEmailVerified) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.emailVerified, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],

                    const Spacer(),

                    // [다음] 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        // 이메일 인증이 완료되어야만 다음으로 진행 가능
                        onPressed: widget.isEmailVerified ? widget.onNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: widget.isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(AppLocalizations.of(context)!.next, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
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