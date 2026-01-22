import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/search_trigger.dart'; // ✅ 클릭 시 지도 이동을 위해 추가

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
  List<Map<String, dynamic>> _lists = []; // 사용자 정의 리스트 목록

  // ✅ 카운트 변수들
  Map<String, int> _listCounts = {}; // 각 리스트별 아이템 개수
  int _savedStoresCount = 0; // "저장한 매장" 전체 개수

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // ✅ 데이터 한 번에 로드
  Future<void> _fetchAllData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 사용자 리스트 목록 가져오기
      final listRes = await _supabase
          .from('user_lists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // 2. "저장한 매장" (북마크) 전체 개수 가져오기
      // ✅ 중복 저장(주소 공백/표기 차이 등) 방어를 위해
      //    store_saves 대신 "중복 제거 뷰"에서 count 합니다.
      final savedCount = await _supabase
          .from('store_saves_distinct_view')
          .count(CountOption.exact)
          .eq('user_id', userId);

      if (!mounted) return;

      setState(() {
        _lists = List<Map<String, dynamic>>.from(listRes);
        _savedStoresCount = savedCount;
      });

      // 3. 각 리스트별 아이템 개수 가져오기
      await _fetchCountsForCustomLists();
    } catch (e) {
      debugPrint('데이터 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 사용자 리스트 내부의 아이템 개수 세기
  Future<void> _fetchCountsForCustomLists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _lists.isEmpty) return;

    try {
      final ids = _lists.map((e) => (e['id'] ?? '').toString()).toList();

      final futures = ids.map((id) async {
        final count = await _supabase
            .from('user_list_items')
            .count(CountOption.exact)
            .eq('list_id', id);
        return MapEntry(id, count);
      });

      final results = await Future.wait(futures);

      if (!mounted) return;
      setState(() {
        _listCounts = Map.fromEntries(results);
      });
    } catch (e) {
      debugPrint('리스트 개수 로드 실패: $e');
    }
  }

  // ✅ 매장 클릭 시 지도로 이동하는 로직
  void _goToMapWithStore(String storeName, String? address) {
    if (storeName.isEmpty) return;

    // 1. 전역 검색 트리거 설정
    searchTrigger.value = SearchTarget(
      query: storeName,
      // 주소가 있다면 더 정확한 검색을 위해 포함 가능
    );

    // 2. 홈(지도 탭이 있는) 화면으로 복귀
    Navigator.of(context).popUntil((route) => route.isFirst);

    // 3. (선택) 만약 BottomNavigationBar를 사용하는 경우 탭 인덱스를 '내 주변'으로 바꿔줘야 할 수도 있습니다.
    // 보통 searchTrigger를 리스닝하는 MapScreen이 있다면 자동으로 지도가 이동합니다.
  }

  Future<void> _createList() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
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
              const Text("새 리스트 만들기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                "리스트를 만든 후 저장한 매장을 담을 수 있어요.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "예: 데이트 맛집, 회식 장소",
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A2BE2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("생성",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
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
    if (name.isEmpty) return;

    try {
      await _supabase.from('user_lists').insert({
        'user_id': userId,
        'name': name,
      });

      await _fetchAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("리스트가 생성되었습니다. 매장을 추가해보세요!")),
        );
      }
    } catch (e) {
      debugPrint('리스트 생성 실패: $e');
    }
  }

  Future<void> _deleteList(String listId) async {
    try {
      await _supabase.from('user_lists').delete().eq('id', listId);
      await _fetchAllData();
    } catch (e) {
      debugPrint('리스트 삭제 실패: $e');
    }
  }

  void _openSavedStores() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedStoresScreen()),
    );
    _fetchAllData();
  }

  void _openListDetail(String listId, String listName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyListDetailScreen(listId: listId, listName: listName),
      ),
    );
    _fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("나만의 리스트",
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _createList,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchAllData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ✅ 1. '저장한 매장' 카드
            _ListCard(
              title: "저장한 매장",
              countText: _savedStoresCount > 0 ? "$_savedStoresCount개" : null,
              subtitle: "내가 찜한 모든 매장",
              onTap: _openSavedStores,
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFAEAEB2)),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text("내 리스트",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),

            // ✅ 2. 사용자 리스트 목록
            if (_lists.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.playlist_add,
                        size: 48, color: Color(0xFFD1D1D6)),
                    const SizedBox(height: 16),
                    const Text(
                      "리스트가 없습니다.\n새로운 리스트를 만들어보세요!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _createList,
                      child: const Text("리스트 만들기"),
                    ),
                  ],
                ),
              )
            ] else ...[
              ..._lists.map((item) {
                final id = (item['id'] ?? '').toString();
                final name = (item['name'] ?? '이름 없음').toString();
                final count = _listCounts[id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ListCard(
                    title: name,
                    countText: "$count개",
                    subtitle: count == 0 ? "터치하여 매장 추가하기" : null,
                    onTap: () => _openListDetail(id, name),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz,
                          color: Color(0xFF3A3A3C)),
                      onSelected: (value) {
                        if (value == 'delete') _deleteList(id);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'delete', child: Text("리스트 삭제")),
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
  final String? countText;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget trailing;

  const _ListCard({
    required this.title,
    required this.onTap,
    required this.trailing,
    this.countText,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
              child: const Icon(Icons.folder_open_rounded,
                  color: Color(0xFF8A2BE2), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (countText != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          countText!,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8A2BE2),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8E8E93)),
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
