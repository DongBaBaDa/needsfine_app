import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'notice_write_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  static const Color _brand = Color(0xFF8A2BE2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("관리자 대시보드", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _brand,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _brand,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "건의사항"),
            Tab(text: "1:1 문의"),
            Tab(text: "공지사항"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuggestionList(),
          _buildFeedbackList(),
          _buildNoticeManager(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              backgroundColor: _brand,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoticeWriteScreen()),
                );
                if (result == true) setState(() {});
              },
            )
          : null,
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 1. 건의사항 리스트 (suggestions 테이블)
  // ───────────────────────────────────────────────────────────────
  Widget _buildSuggestionList() {
    return FutureBuilder(
      future: _supabase.from('suggestions').select('*, profiles(nickname)').order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data as List<dynamic>;

        if (list.isEmpty) {
          return _buildEmptyState("받은 건의사항이 없습니다.", Icons.inbox_outlined);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
            itemBuilder: (context, index) => _buildItemTile(
              item: list[index],
              type: 'suggestion',
              contentKey: 'content',
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 2. 1:1 문의 리스트 (feedback 테이블)
  // ───────────────────────────────────────────────────────────────
  Widget _buildFeedbackList() {
    return FutureBuilder(
      future: _supabase.from('feedback').select('*, profiles(nickname)').order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data as List<dynamic>;

        if (list.isEmpty) {
          return _buildEmptyState("받은 1:1 문의가 없습니다.", Icons.mail_outline);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
            itemBuilder: (context, index) => _buildItemTile(
              item: list[index],
              type: 'feedback',
              contentKey: 'content',  // feedback 테이블도 content 사용
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 3. 공지사항 관리
  // ───────────────────────────────────────────────────────────────
  Widget _buildNoticeManager() {
    return FutureBuilder(
      future: _supabase.from('notices').select().order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data as List<dynamic>;

        if (list.isEmpty) {
          return _buildEmptyState("등록된 공지사항이 없습니다.\n+ 버튼을 눌러 작성하세요.", Icons.campaign_outlined);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
            itemBuilder: (context, index) {
              final item = list[index];
              final date = DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(item['created_at']));

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign, color: _brand),
                ),
                title: Text(item['title'] ?? '제목 없음',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _deleteNotice(item['id']),
                ),
                onTap: () => _showDetailDialog(
                  title: item['title'] ?? '공지사항',
                  content: item['content'] ?? '',
                  date: date,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 공통 UI: 아이템 타일 (건의사항, 1:1 문의)
  // ───────────────────────────────────────────────────────────────
  Widget _buildItemTile({
    required Map<String, dynamic> item,
    required String type,
    required String contentKey,
  }) {
    final date = DateFormat('MM.dd HH:mm').format(DateTime.parse(item['created_at']));
    final nickname = item['profiles']?['nickname'] ?? '익명';
    final content = item[contentKey] ?? '';
    final email = item['email'] ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: type == 'suggestion' 
              ? Colors.orange.withOpacity(0.1) 
              : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          type == 'suggestion' ? Icons.lightbulb_outline : Icons.mail_outline,
          color: type == 'suggestion' ? Colors.orange : Colors.blue,
        ),
      ),
      title: Text(
        content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Text(nickname, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
            Text(" · ", style: TextStyle(color: Colors.grey[400])),
            Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
      onTap: () => _showDetailDialog(
        title: type == 'suggestion' ? '건의사항' : '1:1 문의',
        content: content,
        date: date,
        sender: nickname,
        email: email,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 공통 UI: 빈 상태
  // ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 상세 다이얼로그
  // ───────────────────────────────────────────────────────────────
  void _showDetailDialog({
    required String title,
    required String content,
    required String date,
    String? sender,
    String? email,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sender != null) ...[
                Text("보낸 사람: $sender", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
              ],
              if (email != null && email.isNotEmpty) ...[
                Text("이메일: $email", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("닫기"),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 공지사항 삭제
  // ───────────────────────────────────────────────────────────────
  Future<void> _deleteNotice(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("공지사항 삭제"),
        content: const Text("정말 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.from('notices').delete().eq('id', id);
      setState(() {});
    }
  }
}