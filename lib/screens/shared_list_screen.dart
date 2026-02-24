import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/screens/initial_screen.dart';

class SharedListScreen extends StatefulWidget {
  final String listId;

  const SharedListScreen({super.key, required this.listId});

  @override
  State<SharedListScreen> createState() => _SharedListScreenState();
}

class _SharedListScreenState extends State<SharedListScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _listName = '공유된 리스트';
  String _authorName = '익명';
  List<Review> _items = [];
  bool _isNotFound = false;

  @override
  void initState() {
    super.initState();
    _fetchSharedList();
  }

  Future<void> _fetchSharedList() async {
    try {
      // 1. 리스트 정보 가져오기 (profiles 조인 제거하여 400 에러 방지)
      final listRes = await _supabase
          .from('user_lists')
          .select('name, is_public')
          .eq('id', widget.listId)
          .maybeSingle();

      if (listRes == null || listRes['is_public'] != true) {
        if (mounted) setState(() {
          _isNotFound = true;
          _isLoading = false;
        });
        return;
      }

      _listName = listRes['name'] ?? '공유된 리스트';
      _authorName = '익명';

      // 2. 리스트 아이템(리뷰 ID) 가져오기
      final rows = await _supabase
          .from('user_list_items')
          .select('review_id')
          .eq('list_id', widget.listId);

      final reviewIds = List<Map<String, dynamic>>.from(rows)
          .map((e) => (e['review_id'] ?? '').toString())
          .where((v) => v.isNotEmpty)
          .toList();

      if (reviewIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 3. 리뷰 데이터 가져오기 (비로그인 상태라도 public 데이터를 읽을 수 있어야 함)
      final reviewRes = await _supabase
          .from('reviews')
          .select('*, store_lat, store_lng')
          .inFilter('id', reviewIds);

      final reviewMap = <String, Map<String, dynamic>>{
        for (final r in List<Map<String, dynamic>>.from(reviewRes))
          (r['id'] ?? '').toString(): Map<String, dynamic>.from(r),
      };

      final items = <Review>[];
      for (final id in reviewIds) {
        final json = reviewMap[id];
        if (json != null) {
          items.add(Review.fromJson(json));
        }
      }

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('공유 리스트 로드 실패: $e');
      if (mounted) setState(() {
        _isNotFound = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _supabase.auth.currentUser != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(_listName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isNotFound
          ? const Center(
              child: Text(
                '리스트를 찾을 수 없거나\n비공개 상태입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B6B6F), height: 1.4, fontSize: 16),
              ),
            )
          : Stack(
              children: [
                ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, isLoggedIn ? 40 : 120),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rv = _items[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rv.storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(rv.storeAddress ?? '주소 정보 없음', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Text('니즈파인', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3A3A3C))),
                                    const SizedBox(width: 4),
                                    Text(rv.needsfineScore.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8A2BE2))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Text('신뢰도', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3A3A3C))),
                                    const SizedBox(width: 4),
                                    Text('${rv.trustLevel}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8A2BE2))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (!isLoggedIn)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '진짜 리뷰가 궁금하다면?',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '광고 없는 진짜 리뷰 앱, 니즈파인을 시작해보세요.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const InitialScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC87CFF),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('니즈파인 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
