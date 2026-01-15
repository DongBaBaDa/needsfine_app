import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class NoticeWriteScreen extends StatefulWidget {
  const NoticeWriteScreen({super.key});

  @override
  State<NoticeWriteScreen> createState() => _NoticeWriteScreenState();
}

class _NoticeWriteScreenState extends State<NoticeWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isUploading = false;

  Future<void> _uploadNotice() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("제목과 내용을 모두 입력해주세요.")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _supabase.from('notices').insert({
        'title': _titleController.text,
        'content': _contentController.text,
        // created_at은 DB에서 자동으로 생성됨
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("공지사항이 등록되었습니다.")));
      Navigator.pop(context, true); // true를 반환해서 목록을 새로고침하게 함
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("업로드 실패: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(title: const Text("공지사항 작성 (관리자)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "제목",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null, // 무제한 줄바꿈
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: "내용",
                  hintText: "공지할 내용을 입력하세요.",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeedsFinePurple,
                  foregroundColor: Colors.white,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("등록하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}