import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/admin/admin_inquiry_detail_screen.dart';
import 'notice_write_screen.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.adminDashboard, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _brand,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _brand,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: l10n.suggestions),
            Tab(text: l10n.inquiry),
            Tab(text: l10n.notices),
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
        if (snapshot.hasError) return Center(child: Text("오류 발생: ${snapshot.error}")); // 에러 표시
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data as List<dynamic>;
        final l10n = AppLocalizations.of(context)!;

        if (list.isEmpty) {
          return _buildEmptyState(l10n.noSuggestions, Icons.inbox_outlined);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100), // Add bottom padding
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
        final l10n = AppLocalizations.of(context)!;

        if (list.isEmpty) {
          return _buildEmptyState(l10n.noInquiries, Icons.mail_outline);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100), // Add bottom padding
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
        final l10n = AppLocalizations.of(context)!;

        if (list.isEmpty) {
          return _buildEmptyState(l10n.noNoticesAdmin, Icons.campaign_outlined);
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
                title: Text(item['title'] ?? l10n.noTitle,
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
                  title: item['title'] ?? l10n.notice,
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
    final l10n = AppLocalizations.of(context)!;
    final nickname = item['profiles']?['nickname'] ?? l10n.anonymous;
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
            if (type == 'feedback') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item['answer'] != null ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item['answer'] != null ? l10n.completed : l10n.pending,
                  style: TextStyle(
                    color: item['answer'] != null ? Colors.green : Colors.red,
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminInquiryDetailScreen(
              data: item,
              type: type,
            ),
          ),
        );
        if (result == true) setState(() {});
      },
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
    final l10n = AppLocalizations.of(context)!;
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
                Text("${l10n.sender}: $sender", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
              ],
              if (email != null && email.isNotEmpty) ...[
                Text("Email: $email", style: TextStyle(color: Colors.grey[600], fontSize: 13)), // Email is mostly universal
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
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 공지사항 삭제
  // ───────────────────────────────────────────────────────────────
  Future<void> _deleteNotice(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNotice),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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