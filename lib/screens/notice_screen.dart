import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'notice_write_screen.dart'; // ✅ 작성 화면 import

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _supabase = Supabase.instance.client;

  // 🔴 관리자 이메일 설정 (여기에 너의 관리자 계정 이메일을 정확히 입력해)
  final String _adminEmail = 'ineedsfine@gmail.com';

  Future<List<Map<String, dynamic>>> _fetchNotices() async {
    final data = await _supabase
        .from('notices')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // 관리자인지 확인하는 함수
  bool _isAdmin() {
    final user = _supabase.auth.currentUser;
    return user != null && user.email == _adminEmail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(title: const Text("공지사항")),

      // ✅ 관리자일 때만 글쓰기 버튼 표시
      floatingActionButton: _isAdmin()
          ? FloatingActionButton(
        backgroundColor: kNeedsFinePurple,
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () async {
          // 글쓰기 화면으로 이동하고, 돌아왔을 때(result가 true면) 화면 새로고침
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoticeWriteScreen()),
          );
          if (result == true) {
            setState(() {}); // 목록 새로고침
          }
        },
      )
          : null,

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("에러가 발생했습니다: ${snapshot.error}"));
          }
          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return const Center(child: Text("등록된 공지사항이 없습니다."));
          }

          return ListView.separated(
            itemCount: notices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notice = notices[index];
              final date = DateTime.parse(notice['created_at']);
              final formattedDate = DateFormat('yyyy.MM.dd').format(date);

              return ExpansionTile(
                title: Text(notice['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Text(
                      notice['content'],
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}