import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'notice_write_screen.dart'; // 공지사항 작성 화면 import

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: const Text("소중한 피드백 (관리자)"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kNeedsFinePurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kNeedsFinePurple,
          tabs: const [
            Tab(text: "받은 건의사항"),
            Tab(text: "공지사항 관리"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedbackList(), // 탭 1: 건의사항 보기
          _buildNoticeManager(), // 탭 2: 공지사항 관리
        ],
      ),
      // 공지사항 탭일 때만 글쓰기 버튼 표시
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNeedsFinePurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // 탭 인덱스가 1(공지사항)일 때만 작성 화면으로 이동
          if (_tabController.index == 1) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NoticeWriteScreen()),
            );
            if (result == true) setState(() {}); // 돌아오면 새로고침
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("공지사항 탭에서만 작성 가능합니다.")));
          }
        },
      ),
    );
  }

  // 1. 받은 건의사항 리스트 (Suggestions + Feedback)
  Widget _buildFeedbackList() {
    return FutureBuilder(
      // 건의사항(suggestions) 테이블 조회
      future: _supabase.from('suggestions').select('*, profiles(nickname)').order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data as List<dynamic>;

        if (list.isEmpty) return const Center(child: Text("도착한 건의사항이 없습니다."));

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final date = DateFormat('MM/dd HH:mm').format(DateTime.parse(item['created_at']));
            final nickname = item['profiles'] != null ? item['profiles']['nickname'] : '익명';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.mark_email_unread_outlined, color: kNeedsFinePurple),
                title: Text(item['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text("$nickname · $date"),
                onTap: () {
                  // 클릭 시 전체 내용 보기 팝업
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("보낸 사람: $nickname"),
                      content: Text(item['content']),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // 2. 공지사항 관리 리스트 (내가 쓴 공지사항)
  Widget _buildNoticeManager() {
    return FutureBuilder(
      future: _supabase.from('notices').select().order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data as List<dynamic>;

        if (list.isEmpty) return const Center(child: Text("등록된 공지사항이 없습니다. + 버튼을 눌러 작성하세요."));

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final date = DateFormat('yyyy.MM.dd').format(DateTime.parse(item['created_at']));

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              elevation: 2,
              child: ListTile(
                title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(date),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    // 삭제 기능
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("공지사항 삭제"),
                        content: const Text("정말 삭제하시겠습니까?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _supabase.from('notices').delete().eq('id', item['id']);
                      setState(() {}); // 새로고침
                    }
                  },
                ),
                onTap: () {
                  // 상세 내용 보기
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(item['title']),
                      content: SingleChildScrollView(child: Text(item['content'])),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}