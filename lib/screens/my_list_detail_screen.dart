import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/core/search_trigger.dart';

class MyListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const MyListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<MyListDetailScreen> createState() => _MyListDetailScreenState();
}

class _MyListDetailScreenState extends State<MyListDetailScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Review> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchListItems();
  }

  Future<void> _fetchListItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rows = await _supabase
          .from('user_list_items')
          .select('review_id, created_at')
          .eq('user_id', userId)
          .eq('list_id', widget.listId)
          .order('created_at', ascending: false);

      final listRows = List<Map<String, dynamic>>.from(rows);
      final reviewIds = listRows.map((e) => (e['review_id'] ?? '').toString()).where((v) => v.isNotEmpty).toList();

      if (reviewIds.isEmpty) {
        if (mounted) setState(() {
          _items = [];
          _isLoading = false;
        });
        return;
      }

      final reviewRes = await _supabase.from('reviews').select().inFilter('id', reviewIds);
      final reviewMap = <String, Map<String, dynamic>>{
        for (final r in List<Map<String, dynamic>>.from(reviewRes))
          (r['id'] ?? '').toString(): Map<String, dynamic>.from(r),
      };

      // 기존 order 유지
      final items = <Review>[];
      for (final id in reviewIds) {
        final json = reviewMap[id];
        if (json != null) items.add(Review.fromJson(json));
      }

      if (mounted) setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('리스트 아이템 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToMap(Review review) {
    if (review.storeName.isNotEmpty) {
      searchTrigger.value = SearchTarget(
        query: review.storeName,
        lat: review.storeLat,
        lng: review.storeLng,
      );
      Navigator.pop(context);
    }
  }

  Future<List<Review>> _loadSavedReviews() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final savedRows = await _supabase
        .from('review_saves')
        .select('review_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final s = List<Map<String, dynamic>>.from(savedRows);
    final ids = s.map((e) => (e['review_id'] ?? '').toString()).where((v) => v.isNotEmpty).toList();
    if (ids.isEmpty) return [];

    final reviewRes = await _supabase.from('reviews').select().inFilter('id', ids);
    final reviewMap = <String, Map<String, dynamic>>{
      for (final r in List<Map<String, dynamic>>.from(reviewRes))
        (r['id'] ?? '').toString(): Map<String, dynamic>.from(r),
    };

    final list = <Review>[];
    for (final id in ids) {
      final json = reviewMap[id];
      if (json != null) list.add(Review.fromJson(json));
    }
    return list;
  }

  Future<void> _addReviewsToList(List<String> reviewIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (reviewIds.isEmpty) return;

    try {
      final payload = reviewIds.map((rid) => {
        'user_id': userId,
        'list_id': widget.listId,
        'review_id': rid,
      }).toList();

      await _supabase.from('user_list_items').upsert(
        payload,
        onConflict: 'list_id,review_id',
      );

      await _fetchListItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("리스트에 추가했습니다.")));
      }
    } catch (e) {
      debugPrint('리스트 추가 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("추가에 실패했습니다.")));
      }
    }
  }

  Future<void> _removeFromList(String reviewId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('user_list_items')
          .delete()
          .eq('user_id', userId)
          .eq('list_id', widget.listId)
          .eq('review_id', reviewId);

      await _fetchListItems();
    } catch (e) {
      debugPrint('리스트 항목 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제에 실패했습니다.")));
      }
    }
  }

  Future<void> _openAddBottomSheet() async {
    final existing = _items.map((e) => (e.id ?? '').toString()).where((e) => e.isNotEmpty).toSet();

    final saved = await _loadSavedReviews();
    if (!mounted) return;

    if (saved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장한 매장이 없습니다.")));
      return;
    }

    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(99))),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("저장한 매장 추가", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 420,
                      child: ListView.separated(
                        itemCount: saved.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final r = saved[index];
                          final rid = (r.id ?? '').toString();
                          final already = existing.contains(rid);

                          return ListTile(
                            enabled: !already,
                            onTap: already
                                ? null
                                : () {
                              setModalState(() {
                                if (selected.contains(rid)) {
                                  selected.remove(rid);
                                } else {
                                  selected.add(rid);
                                }
                              });
                            },
                            leading: Icon(
                              already
                                  ? Icons.check_circle
                                  : (selected.contains(rid) ? Icons.check_circle : Icons.radio_button_unchecked),
                              color: already ? Colors.grey : const Color(0xFF8A2BE2),
                            ),
                            title: Text(
                              r.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: already ? Colors.grey : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              r.storeAddress ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: already ? Colors.grey : Colors.grey[600], fontSize: 12),
                            ),
                            trailing: already ? const Text("추가됨", style: TextStyle(color: Colors.grey, fontSize: 12)) : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () async {
                          Navigator.pop(context);
                          await _addReviewsToList(selected.toList());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          selected.isEmpty ? "추가할 항목을 선택하세요" : "${selected.length}개 추가하기",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(widget.listName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _openAddBottomSheet, // ✅ (요청 1) 리스트에서 +로 저장한 매장 추가
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: "저장한 매장 추가",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
        child: Text(
          "아직 리스트에 담긴 매장이 없습니다.\n우측 상단 +로 저장한 매장을 추가해보세요.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B6B6F), height: 1.4),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final r = _items[index];
          final rid = (r.id ?? '').toString();

          return Container(
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
            child: ListTile(
              onTap: () => _goToMap(r),
              title: Text(r.storeName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(r.storeAddress ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                tooltip: "리스트에서 제거",
                onPressed: () => _removeFromList(rid),
              ),
            ),
          );
        },
      ),
    );
  }
}
