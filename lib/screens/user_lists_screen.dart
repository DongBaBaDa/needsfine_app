import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/my_list_detail_screen.dart'; // 상세 화면 연결

class UserListsScreen extends StatefulWidget {
  final String userId;
  final String nickname;

  const UserListsScreen({
    super.key,
    required this.userId,
    required this.nickname,
  });

  @override
  State<UserListsScreen> createState() => _UserListsScreenState();
}

class _UserListsScreenState extends State<UserListsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _lists = [];
  Map<String, int> _listCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchUserLists();
  }

  Future<void> _fetchUserLists() async {
    try {
      // 1. 해당 유저의 리스트 가져오기
      final res = await _supabase
          .from('user_lists')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _lists = List<Map<String, dynamic>>.from(res);
      });

      // 2. 각 리스트의 아이템 개수 가져오기
      await _fetchCounts();
    } catch (e) {
      debugPrint('유저 리스트 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCounts() async {
    final ids = _lists.map((e) => (e['id'] ?? '').toString()).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;

    try {
      final futures = ids.map((id) async {
        final c = await _supabase
            .from('user_list_items')
            .count(CountOption.exact)
            .eq('user_id', widget.userId)
            .eq('list_id', id);
        return MapEntry(id, c);
      });

      final results = await Future.wait(futures);

      if (!mounted) return;
      setState(() {
        for (final entry in results) {
          _listCounts[entry.key] = entry.value;
        }
      });
    } catch (e) {
      debugPrint('개수 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          "${widget.nickname}님의 리스트",
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
          ? Center(
        child: Text(
          "생성된 리스트가 없습니다.",
          style: TextStyle(color: Colors.grey[500]),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _lists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final list = _lists[index];
          final id = list['id'].toString();
          final name = list['name'] ?? '이름 없음';
          final count = _listCounts[id] ?? 0;

          return GestureDetector(
            onTap: () {
              // 리스트 상세 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyListDetailScreen(
                    listId: id,
                    listName: name,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.list_alt_rounded, color: Color(0xFF8A2BE2), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "저장된 매장 $count개",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}