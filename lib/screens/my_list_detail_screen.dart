import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

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

  // ------------------------------
  // ✅ 문자열 정규화 (SQL norm_text와 동일한 의도)
  // ------------------------------
  String _norm(String? s) {
    final v = (s ?? '').toLowerCase().trim();
    return v.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _pairKey(String storeName, String? storeAddress) {
    return '${_norm(storeName)}|${_norm(storeAddress)}';
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
          .eq('list_id', widget.listId)
          .order('created_at', ascending: false);

      final listRows = List<Map<String, dynamic>>.from(rows);
      final reviewIds = listRows
          .map((e) => (e['review_id'] ?? '').toString())
          .where((v) => v.isNotEmpty)
          .toList();

      if (reviewIds.isEmpty) {
        if (mounted) {
          setState(() {
            _items = [];
            _isLoading = false;
          });
        }
        return;
      }

      final reviewRes = await _supabase
          .from('reviews')
          .select('*, store_lat, store_lng')
          .inFilter('id', reviewIds);
      final reviewMap = <String, Map<String, dynamic>>{
        for (final r in List<Map<String, dynamic>>.from(reviewRes))
          (r['id'] ?? '').toString(): Map<String, dynamic>.from(r),
      };

      // 기존 order 유지
      final items = <Review>[];
      final orphanedReviewIds = <String>[]; // ✅ 삭제된 리뷰 ID 수집
      
      for (final id in reviewIds) {
        final json = reviewMap[id];
        if (json != null) {
          items.add(Review.fromJson(json));
        } else {
          debugPrint('⚠️ 리뷰를 찾을 수 없음: $id (DB에만 존재, 삭제된 리뷰)');
          orphanedReviewIds.add(id);
        }
      }

      // ✅ 삭제된 리뷰가 있으면 user_list_items에서 자동 제거
      if (orphanedReviewIds.isNotEmpty) {
        try {
          await _supabase
              .from('user_list_items')
              .delete()
              .eq('list_id', widget.listId)
              .inFilter('review_id', orphanedReviewIds);
          debugPrint('✅ 삭제된 리뷰 ${orphanedReviewIds.length}개를 리스트에서 제거했습니다.');
        } catch (e) {
          debugPrint('삭제된 리뷰 정리 실패: $e');
        }
      }

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('리스트 아이템 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToMap(Review review) {
    if (review.storeName.isEmpty) return;
    
    // ✅ 최적화: Navigator.pop과 searchTrigger를 동시에 처리
    Navigator.pop(context);
    
    // ✅ 즉시 실행하여 화면 전환 속도 향상
    Future.microtask(() {
      searchTrigger.value = SearchTarget(
        query: review.storeName,
        lat: review.storeLat != 0.0 ? review.storeLat : null,
        lng: review.storeLng != 0.0 ? review.storeLng : null,
      );
    });
  }

  // ==========================================================
  // ✅ (수정) "저장한 매장"은 review_saves가 아니라 store_saves를 봐야 함
  // ==========================================================
  Future<List<Map<String, dynamic>>> _loadSavedStores() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // ✅ 중복 제거 뷰 사용 (최신 1개만)
    final rows = await _supabase
        .from('store_saves_distinct_view')
        .select('id, user_id, store_key, store_name, store_address, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  // ✅ 선택한 매장(store_name/address) -> reviews에서 최신 리뷰 1개 id로 변환
  // (스키마 안 건드리고 기존 user_list_items(review_id uuid) 유지하기 위한 최소 연결)
  Future<List<String>> _resolveReviewIdsFromStores(List<Map<String, dynamic>> stores) async {
    final ids = <String>[];

    for (final s in stores) {
      final name = (s['store_name'] ?? '').toString();
      final addr = (s['store_address'] ?? '').toString();

      if (name.isEmpty) continue;

      try {
        debugPrint('🔍 매장 검색: $name (주소: $addr)');
        
        // ✅ 해당 매장의 최신 리뷰 1개를 대표로 사용
        final res = await _supabase
            .from('reviews')
            .select('id')
            .eq('store_name', name)
            .eq('store_address', addr)
            .order('created_at', ascending: false)
            .limit(1);

        final list = List<Map<String, dynamic>>.from(res);
        if (list.isNotEmpty) {
          final rid = (list.first['id'] ?? '').toString();
          if (rid.isNotEmpty) {
            debugPrint('✅ 리뷰 찾음: $rid');
            ids.add(rid);
          }
        } else {
          debugPrint('⚠️ 리뷰 없음: $name (주소 불일치 가능성)');
        }
      } catch (e) {
        debugPrint('❌ 리뷰 id 변환 실패: $name - $e');
      }
    }

    debugPrint('🎯 총 변환된 리뷰 ID: ${ids.length}개');
    return ids;
  }

  Future<void> _addReviewsToList(List<String> reviewIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (reviewIds.isEmpty) return;

    try {
      final payload = reviewIds
          .map((rid) => {
        'user_id': userId,
        'list_id': widget.listId,
        'review_id': rid,
      })
          .toList();

      await _supabase.from('user_list_items').upsert(
        payload,
        onConflict: 'list_id,review_id',
      );

      await _fetchListItems();
  // ... inside _addReviewsToList ...
      await _fetchListItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.addedToList)));
      }
    } catch (e) {
      debugPrint('리스트 추가 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.addFailed)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deleteFailed)));
      }
    }
  }

  Future<void> _openAddBottomSheet() async {
    final l10n = AppLocalizations.of(context)!;
    // ✅ 이미 리스트에 들어있는 "매장"을 (storeName+address 정규화) 기준으로 집합화
    final existingStorePairs = _items
        .map((e) => _pairKey(e.storeName, e.storeAddress))
        .where((v) => v.isNotEmpty)
        .toSet();

    // ✅ 바텀시트 열 때마다 최신 저장한 매장 조회
    final savedStores = await _loadSavedStores();
    if (!mounted) return;

    if (savedStores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noSavedStores)));
      return;
    }

    // 선택은 store_key 기준(중복 제거/토글 안정)
    final selectedStoreKeys = <String>{};

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
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(99)),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.addSavedStore, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 420,
                      child: ListView.separated(
                        itemCount: savedStores.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final s = savedStores[index];

                          final storeKey = (s['store_key'] ?? '').toString();
                          final storeName = (s['store_name'] ?? '').toString();
                          final storeAddr = (s['store_address'] ?? '').toString();

                          final already = existingStorePairs.contains(_pairKey(storeName, storeAddr));

                          return ListTile(
                            enabled: !already,
                            onTap: already
                                ? null
                                : () {
                              setModalState(() {
                                if (selectedStoreKeys.contains(storeKey)) {
                                  selectedStoreKeys.remove(storeKey);
                                } else {
                                  selectedStoreKeys.add(storeKey);
                                }
                              });
                            },
                            leading: Icon(
                              already
                                  ? Icons.check_circle
                                  : (selectedStoreKeys.contains(storeKey) ? Icons.check_circle : Icons.radio_button_unchecked),
                              color: already ? Colors.grey : const Color(0xFF8A2BE2),
                            ),
                            title: Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: already ? Colors.grey : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              storeAddr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: already ? Colors.grey : Colors.grey[600], fontSize: 12),
                            ),
                            trailing: already ? Text(l10n.added, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedStoreKeys.isEmpty
                            ? null
                            : () async {
                          // ✅ 선택된 매장 row들만 추출
                          final selectedStores = savedStores
                              .where((e) => selectedStoreKeys.contains((e['store_key'] ?? '').toString()))
                              .toList();

                          Navigator.pop(context);

                          // ✅ store -> review_id 변환 후 기존 로직으로 추가
                          final reviewIds = await _resolveReviewIdsFromStores(selectedStores);
                          if (!mounted) return;

                          if (reviewIds.isEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.noReviewsForStore)),
                              );
                            }
                            return;
                          }

                          await _addReviewsToList(reviewIds);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          selectedStoreKeys.isEmpty ? l10n.selectItemsToAdd : l10n.addNItems(selectedStoreKeys.length),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(widget.listName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () async {
              // 1. 공유 시 자동으로 공개 처리
              try {
                await _supabase
                    .from('user_lists')
                    .update({'is_public': true})
                    .eq('id', widget.listId);
              } catch (e) {
                debugPrint('공개 자동 전환 실패: $e');
              }
              
              // 2. 링크 공유
              final text = '니즈파인 맛집 리스트 대공개! ✨\n[${widget.listName}]\n지금 바로 확인해보세요:\nhttps://needsfine.com/list?id=${widget.listId}';
              Share.share(text);
            },
            icon: const Icon(Icons.share, color: Colors.blueAccent),
            tooltip: '공유하기',
          ),
          IconButton(
            onPressed: _openAddBottomSheet, // ✅ (요청 1) 리스트에서 +로 저장한 매장 추가
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: l10n.addSavedStore,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
        child: Text(
          l10n.emptyListHint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B6B6F), height: 1.4),
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
                tooltip: l10n.removeFromList,
                onPressed: () => _removeFromList(rid),
              ),
            ),
          );
        },
      ),
    );
  }
}
