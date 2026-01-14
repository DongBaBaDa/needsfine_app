import 'package:flutter/material.dart';

class StepNickname extends StatelessWidget {
  final TextEditingController nicknameController;
  final ValueChanged<String>? onChanged; // [NEW] 입력 감지용 콜백 추가

  const StepNickname({
    super.key,
    required this.nicknameController,
    this.onChanged, // [NEW]
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: nicknameController,
      onChanged: onChanged, // [NEW] 텍스트가 변할 때마다 호출
      decoration: const InputDecoration(
        labelText: '닉네임',
        hintText: '한글, 영문, 숫자 포함 2~10자',
        prefixIcon: Icon(Icons.person_outline),
      ),
      maxLength: 10,
    );
  }
}