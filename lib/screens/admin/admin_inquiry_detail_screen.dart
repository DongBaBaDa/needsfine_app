import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:intl/intl.dart';

class AdminInquiryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data; // suggestion or feedback data
  final String type; // 'suggestion' or 'inquiry'

  const AdminInquiryDetailScreen({super.key, required this.data, required this.type});

  @override
  State<AdminInquiryDetailScreen> createState() => _AdminInquiryDetailScreenState();
}

class _AdminInquiryDetailScreenState extends State<AdminInquiryDetailScreen> {
  final _answerController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isSending = false;
  String? _existingAnswer;
  DateTime? _answeredAt;

  @override
  void initState() {
    super.initState();
    _existingAnswer = widget.data['answer'];
    if (widget.data['answered_at'] != null) {
      _answeredAt = DateTime.parse(widget.data['answered_at']).toLocal();
    }
    if (_existingAnswer != null) {
      _answerController.text = _existingAnswer!;
    }
  }

  Future<void> _submitAnswer() async {
    // For feedback, require text. For suggestions, allow empty (treat as "Confirmed")
    if (widget.type != 'suggestion' && _answerController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final table = widget.type == 'suggestion' ? 'suggestions' : 'feedback';
      final now = DateTime.now().toIso8601String();
      
      // If suggestion and empty, use "확인 완료" (Confirmed)
      String answerText = _answerController.text;
      if (widget.type == 'suggestion' && answerText.trim().isEmpty) {
        answerText = "확인 완료";
      }

      await _supabase.from(table).update({
        'answer': answerText,
        'answered_at': now,
      }).eq('id', widget.data['id']);

      // TODO: Send Push Notification to User (Need implementation in index.ts or trigger)
      // For now, just save to DB.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("답변이 등록되었습니다.")));
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("답변 등록 실패: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.data['created_at']).toLocal();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
    final user = widget.data['profiles'] ?? {};
    final nickname = user['nickname'] ?? '알 수 없음';
    final email = widget.data['email'] ?? '이메일 없음';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'suggestion' ? "건의사항 답변" : "1:1 문의 답변"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text("작성자: $nickname", style: const TextStyle(fontWeight: FontWeight.bold)),
                       Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text("이메일: $email", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                   const SizedBox(height: 16),
                   const Text("내용:", style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text(widget.data['content'] ?? '', style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Answer Section
            const Text("답변 작성", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: "답변 내용을 입력하세요...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeedsFinePurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSending 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.type == 'suggestion' 
                            ? (_existingAnswer == null ? "확인 완료 (Confirm)" : "답변 수정")
                            : (_existingAnswer == null ? "답변 등록" : "답변 수정"),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
              ),
            ),
             if (_answeredAt != null)
               Padding(
                 padding: const EdgeInsets.only(top: 12),
                 child: Center(
                   child: Text(
                     "답변 등록일: ${DateFormat('yyyy-MM-dd HH:mm').format(_answeredAt!)}",
                     style: const TextStyle(color: Colors.grey, fontSize: 12),
                   ),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
