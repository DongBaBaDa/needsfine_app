import 'package:flutter/material.dart';

class StepNickname extends StatefulWidget {
  final TextEditingController nicknameController;
  final VoidCallback onNext; // [중요] onComplete나 isLoading이 아님
  final ValueChanged<String>? onChanged;

  const StepNickname({
    super.key,
    required this.nicknameController,
    required this.onNext,
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
          const Text('닉네임을 정해주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('나중에 언제든 변경할 수 있어요.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 40),

          TextFormField(
            controller: widget.nicknameController,
            onChanged: widget.onChanged,
            decoration: const InputDecoration(
              labelText: '닉네임',
              hintText: '한글, 영문, 숫자 포함 2~10자',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            maxLength: 10,
          ),

          const Spacer(),

          // 다음 버튼
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}