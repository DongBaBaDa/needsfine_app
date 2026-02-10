import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/user_inquiry_detail_screen.dart';

class UserInquiryHistoryScreen extends StatefulWidget {
  const UserInquiryHistoryScreen({super.key});

  @override
  State<UserInquiryHistoryScreen> createState() => _UserInquiryHistoryScreenState();
}

class _UserInquiryHistoryScreenState extends State<UserInquiryHistoryScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("나의 문의 내역"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kNeedsFinePurple,
          tabs: const [
            Tab(text: "1:1 문의"),
            Tab(text: "건의사항"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('feedback'),
          _buildList('suggestions'),
        ],
      ),
    );
  }

  Widget _buildList(String table) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Center(child: Text("로그인이 필요합니다."));

    return FutureBuilder(
      future: _supabase.from(table).select().eq('user_id', userId).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data as List<dynamic>;

        if (list.isEmpty) {
          return Center(
            child: Text(table == 'feedback' ? "문의 내역이 없습니다." : "건의 내역이 없습니다.", style: const TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // ✅ Bottom padding added
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = list[index];
            final date = DateFormat('yyyy.MM.dd').format(DateTime.parse(item['created_at']).toLocal());
            final content = item['content'] ?? item['message'] ?? '';
            final answer = item['answer'];
            final isAnswered = answer != null && (answer as String).isNotEmpty;
            final isSuggestion = table == 'suggestions';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInquiryDetailScreen(
                      data: item,
                      type: table == 'feedback' ? 'feedback' : 'suggestion',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ✅ Status Badge Logic Updated
                        if (!isSuggestion || isAnswered) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAnswered ? kNeedsFinePurple.withOpacity(0.1) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAnswered 
                                ? (isSuggestion ? "확인완료" : "답변완료") // Confirmed vs Answered
                                : "답변대기", // Pending
                            style: TextStyle(
                              color: isAnswered ? kNeedsFinePurple : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isSuggestion && !isAnswered) const SizedBox.shrink(), // No badge for pending suggestions (as requested)
                        
                        Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(content, style: const TextStyle(fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
