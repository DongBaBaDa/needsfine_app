import 'package:flutter/material.dart';

import 'package:needsfine_app/l10n/app_localizations.dart';

class StepNickname extends StatefulWidget {
  final TextEditingController nicknameController;
  final VoidCallback onComplete; // 가입 완료 액션
  final bool isLoading;
  final ValueChanged<String>? onChanged;

  const StepNickname({
    super.key,
    required this.nicknameController,
    required this.onComplete,
    this.isLoading = false,
    this.onChanged,
  });

  @override
  State<StepNickname> createState() => _StepNicknameState();
}

class _StepNicknameState extends State<StepNickname> {
  bool _isNextEnabled = false;

  @override
  void initState() {
    super.initState();
    widget.nicknameController.addListener(_checkInput);
    _checkInput();
  }

  @override
  void dispose() {
    widget.nicknameController.removeListener(_checkInput);
    super.dispose();
  }

  void _checkInput() {
    final text = widget.nicknameController.text.trim();
    final isEnabled = text.isNotEmpty;
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
          Text(AppLocalizations.of(context)!.setNickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.nicknameInfo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 40),

          TextFormField(
            controller: widget.nicknameController,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.nickname,
              hintText: AppLocalizations.of(context)!.nicknameHint,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            maxLength: 10,
          ),

          const Spacer(),

          // 다음 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isNextEnabled && !widget.isLoading) ? widget.onComplete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: widget.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.completeSignup, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}