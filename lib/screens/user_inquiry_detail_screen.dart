 import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class UserInquiryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type; // 'feedback' or 'suggestion'

  const UserInquiryDetailScreen({super.key, required this.data, required this.type});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(data['created_at']).toLocal();
    final dateStr = DateFormat('yyyy.MM.dd HH:mm').format(date);
    final content = data['content'] ?? data['message'] ?? '';
    final answer = data['answer'];
    final answeredAtStr = data['answered_at'] != null 
        ? DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(data['answered_at']).toLocal())
        : null;
    final isAnswered = answer != null && (answer as String).isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(type == 'feedback' ? "1:1 문의 상세" : "건의사항 상세"),
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
            // 질문 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAnswered ? kNeedsFinePurple : Colors.grey[400],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAnswered ? "답변완료" : "답변대기",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(content, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 답변 섹션
            if (isAnswered)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right_rounded, color: kNeedsFinePurple),
                      const SizedBox(width: 8),
                      const Text("관리자 답변", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if (answeredAtStr != null) ...[
                        const SizedBox(width: 8),
                        Text(answeredAtStr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kNeedsFinePurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kNeedsFinePurple.withOpacity(0.1)),
                    ),
                    child: Text(
                      answer,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "관리자가 내용을 확인하고 있습니다.\n조금만 기다려주세요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 50), // ✅ Bottom padding
          ],
        ),
      ),
    );
  }
}
