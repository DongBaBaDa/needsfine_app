// lib/screens/inquiry_write_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
// ✅ 비속어 필터 임포트
import 'package:needsfine_app/core/profanity_filter.dart';

class InquiryWriteScreen extends StatefulWidget {
  const InquiryWriteScreen({super.key});

  @override
  State<InquiryWriteScreen> createState() => _InquiryWriteScreenState();
}

class _InquiryWriteScreenState extends State<InquiryWriteScreen> {
  final _emailController = TextEditingController(); // 답변 받을 이메일
  final _contentController = TextEditingController(); // 문의 내용
  final _supabase = Supabase.instance.client;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // 로그인한 유저의 이메일을 미리 채워주기
    final userEmail = _supabase.auth.currentUser?.email;
    if (userEmail != null) {
      _emailController.text = userEmail;
    }
  }

  Future<void> _submitInquiry() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("내용을 입력해주세요.")));
      return;
    }

    // ✅ [비속어 필터 적용]
    if (ProfanityFilter.hasProfanity(_contentController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("문의 내용에 부적절한 단어가 포함되어 있습니다."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final userId = _supabase.auth.currentUser?.id;

      // 기존에 존재하던 'feedback' 테이블 활용
      await _supabase.from('feedback').insert({
        'user_id': userId,
        'email': _emailController.text, // 답변 받을 이메일 저장
        'message': _contentController.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("고객님의 소중한 문의가 접수되었습니다. 빠르게 확인하겠습니다.")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("전송 실패: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(title: const Text("1:1 문의하기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "궁금한 점이나 불편한 점을 남겨주세요. 입력하신 이메일로 답변을 보내드립니다.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // 답변 받을 이메일 입력 필드
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "답변 받을 이메일",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // 문의 내용 입력 필드
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: "문의 내용을 자세히 적어주세요...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitInquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeedsFinePurple,
                  foregroundColor: Colors.white,
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("문의하기", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}