import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

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
  
  // ✅ 리스트 공유 상태 관리
  Map<String, bool> _publicStates = {}; // 각 리스트의 공개/비공개 상태
  
  // ✅ 탭 상태 (0: 내 리스트, 1: 공유한 리스트)
  int _currentTab = 0;

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
        // ✅ 공개 상태 초기화 (기본값: false)
        _publicStates = {
          for (final list in _lists)
            (list['id'] ?? '').toString(): (list['is_public'] ?? false) as bool
        };
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
        
        debugPrint('🔍 리스트 ID: $id, 아이템 개수: $count');
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
    final l10n = AppLocalizations.of(context)!;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("로그인이 필요합니다."))); // Keep simple or add key if needed
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
              Text(l10n.newListTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                l10n.newListHint,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.listNamePlaceholder,
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
                  child: Text(l10n.createButton,
                      style: const TextStyle(
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
      // ✅ 기본값: 비공개 (is_public: false)
      await _supabase.from('user_lists').insert({
        'user_id': userId,
        'name': name,
        'is_public': false, // 기본값 비공개
      });

      await _fetchAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.listCreated)),
        );
      }
    } catch (e) {
      debugPrint('리스트 생성 실패: $e');
    }
  }

  Future<void> _deleteList(String listId, String listName) async {
    final l10n = AppLocalizations.of(context)!;
    // ✅ 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteList,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(l10n.deleteListMessage(listName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.deleteList, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ✅ 리스트 삭제 (user_list_items는 CASCADE로 자동 삭제됨)
      await _supabase.from('user_lists').delete().eq('id', listId);
      await _fetchAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.listDeleted)),
        );
      }
    } catch (e) {
      debugPrint('리스트 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteFailed)),
        );
      }
    }
  }

  // ✅ 리스트 공유 토글
  Future<void> _togglePublicState(String listId) async {
    final l10n = AppLocalizations.of(context)!;
    final currentState = _publicStates[listId] ?? false;
    final newState = !currentState;

    try {
      await _supabase
          .from('user_lists')
          .update({'is_public': newState})
          .eq('id', listId);

      setState(() => _publicStates[listId] = newState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newState ? l10n.listShared : l10n.listPrivate),
          ),
        );
      }
    } catch (e) {
      debugPrint('공개 설정 변경 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingFailed)),
        );
      }
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
    final l10n = AppLocalizations.of(context)!;
    
    // ✅ 탭별 리스트 필터링
    final filteredLists = _currentTab == 0
        ? _lists.where((list) {
            final id = (list['id'] ?? '').toString();
            return !(_publicStates[id] ?? false); // 비공개 리스트만
          }).toList()
        : _lists.where((list) {
            final id = (list['id'] ?? '').toString();
            return _publicStates[id] ?? false; // 공개 리스트만
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(l10n.myOwnList,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
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
              title: l10n.savedStores,
              countText: _savedStoresCount > 0 ? l10n.itemCount(_savedStoresCount) : null,
              subtitle: l10n.allSavedStores,
              onTap: _openSavedStores,
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFAEAEB2)),
            ),
            const SizedBox(height: 20),

            // ✅ 탭 UI 추가 (내 리스트 / 공유한 리스트)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 0
                              ? const Color(0xFF8A2BE2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.myListsTab,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _currentTab == 0
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 1
                              ? const Color(0xFF8A2BE2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.sharedListsTab,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _currentTab == 1
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                _currentTab == 0 ? l10n.myListsTab : l10n.sharedListsTab,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            // ✅ 2. 사용자 리스트 목록 (필터링된 리스트)
            if (filteredLists.isEmpty) ...[
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
                    Text(
                      _currentTab == 0
                          ? l10n.noListsYet
                          : l10n.noSharedLists,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF8E8E93)),
                    ),
                    if (_currentTab == 0) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _createList,
                        child: Text(l10n.createList),
                      ),
                    ],
                  ],
                ),
              )
            ] else ...[
              ...filteredLists.map((item) {
                final id = (item['id'] ?? '').toString();
                final name = (item['name'] ?? l10n.noName).toString();
                final count = _listCounts[id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ListCard(
                    title: name,
                    countText: l10n.itemCount(count),
                    subtitle: count == 0 ? l10n.tapToAddStores : null,
                    onTap: () => _openListDetail(id, name),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz,
                          color: Color(0xFF3A3A3C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) async {
                        if (value == 'toggle_public') {
                          _togglePublicState(id);
                        } else if (value == 'share_external') {
                          // 공유 시 자동으로 공개 처리
                          final isPublic = _publicStates[id] ?? false;
                          if (!isPublic) {
                            await _togglePublicState(id);
                          }
                          final text = '니즈파인 맛집 리스트 대공개! ✨\n[$name]\n지금 바로 확인해보세요:\nhttps://needsfine.com/list?id=$id';
                          Share.share(text);
                        } else if (value == 'delete') {
                          _deleteList(id, name);
                        }
                      },
                      itemBuilder: (_) {
                        final isPublic = _publicStates[id] ?? false;
                        return [
                          PopupMenuItem(
                            value: 'toggle_public',
                            child: Row(
                              children: [
                                Icon(
                                  isPublic ? Icons.lock : Icons.public,
                                  size: 20,
                                  color: const Color(0xFF8A2BE2),
                                ),
                                const SizedBox(width: 12),
                                Text(isPublic ? l10n.makePrivate : '공개로 전환'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share_external',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 20, color: Colors.blueAccent),
                                SizedBox(width: 12),
                                Text('공유하기'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.red),
                                const SizedBox(width: 12),
                                Text(l10n.deleteList,
                                    style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ];
                      },
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
