import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class SuggestionWriteScreen extends StatefulWidget {
  const SuggestionWriteScreen({super.key});

  @override
  State<SuggestionWriteScreen> createState() => _SuggestionWriteScreenState();
}

class _SuggestionWriteScreenState extends State<SuggestionWriteScreen> {
  final _controller = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isSending = false;

  Future<void> _submitSuggestion() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("로그인이 필요합니다.");

      // DB에 건의사항 저장
      await _supabase.from('suggestions').insert({
        'user_id': userId,
        'content': _controller.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("소중한 의견이 전달되었습니다.")));
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
      appBar: AppBar(title: const Text("건의사항 보내기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "니즈파인 발전을 위한 의견을 남겨주세요.\n관리자가 직접 확인 후 반영하겠습니다.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: "내용을 입력해주세요...",
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
                onPressed: _isSending ? null : _submitSuggestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeedsFinePurple,
                  foregroundColor: Colors.white,
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("보내기", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}