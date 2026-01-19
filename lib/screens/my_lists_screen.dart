import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ 연결 화면
import 'package:needsfine_app/screens/my_list_detail_screen.dart';
import 'package:needsfine_app/screens/saved_stores_screen.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({super.key});

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _lists = [];

  // ✅ 리스트별 아이템 개수
  final Map<String, int> _listCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _supabase
          .from('user_lists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _lists = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });

      await _fetchCountsForLists(); // ✅ 개수 로드
    } catch (e) {
      debugPrint('리스트 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCountsForLists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final ids = _lists.map((e) => (e['id'] ?? '').toString()).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;

    try {
      final futures = ids.map((id) async {
        final c = await _supabase
            .from('user_list_items')
            .count(CountOption.exact)
            .eq('user_id', userId)
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
      debugPrint('리스트 개수 로드 실패: $e');
    }
  }

  Future<void> _createList() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    final controller = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("새 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "리스트 이름을 입력하세요",
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A2BE2),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("만들기", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (created != true) return;

    final name = controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("리스트 이름을 입력해주세요.")));
      return;
    }

    try {
      await _supabase.from('user_lists').insert({
        'user_id': userId,
        'name': name,
      });

      await _fetchLists();
    } catch (e) {
      debugPrint('리스트 생성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("리스트 생성에 실패했습니다.")));
    }
  }

  Future<void> _deleteList(String listId) async {
    try {
      await _supabase.from('user_lists').delete().eq('id', listId);
      await _fetchLists();
    } catch (e) {
      debugPrint('리스트 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("리스트 삭제에 실패했습니다.")));
    }
  }

  void _openSavedStores() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedStoresScreen()),
    );
  }

  void _openListDetail(String listId, String listName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyListDetailScreen(listId: listId, listName: listName),
      ),
    );

    // ✅ 돌아오면 개수 재반영
    await _fetchLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("나만의 리스트", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _createList,
            tooltip: "리스트 만들기",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchLists,
        color: const Color(0xFF8A2BE2),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ✅ (요청 2) 저장한 매장 -> 저장한 매장 리스트 화면
            _ListCard(
              title: "저장한 매장",
              subtitle: "내가 저장한 매장을 한눈에",
              onTap: _openSavedStores,
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAEAEB2)),
            ),
            const SizedBox(height: 12),

            if (_lists.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
                child: Column(
                  children: [
                    const Text(
                      "저장한 매장을 묶어\n나만의 리스트를 만들어보세요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: Color(0xFF3A3A3C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _createList,
                      icon: const Icon(Icons.add, size: 18, color: Color(0xFF8A2BE2)),
                      label: const Text("리스트 만들기",
                          style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8A2BE2)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._lists.map((item) {
                final id = (item['id'] ?? '').toString();
                final name = (item['name'] ?? '이름 없음').toString();
                final count = _listCounts[id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ListCard(
                    // ✅ (요청 1) 이름 옆에 개수 표시
                    title: "$name  ($count)",
                    subtitle: "저장한 매장을 추가하려면 들어가서 +를 누르세요",
                    onTap: () => _openListDetail(id, name),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: Color(0xFF3A3A3C)),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("삭제 확인"),
                              content: const Text("해당 리스트를 삭제하시겠습니까?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("삭제", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) _deleteList(id);
                        }
                        if (value == 'share') {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text("공유 기능은 다음 단계에서 구현할게요.")));
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'delete', child: Text("해당 리스트 삭제하기")),
                        const PopupMenuItem(value: 'share', enabled: false, child: Text("공유하기 (준비중)")),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget trailing;

  const _ListCard({
    required this.title,
    required this.onTap,
    required this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B6F), height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
