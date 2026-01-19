import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/core/search_trigger.dart';

class SavedStoresScreen extends StatefulWidget {
  const SavedStoresScreen({super.key});

  @override
  State<SavedStoresScreen> createState() => _SavedStoresScreenState();
}

class _SavedStoresScreenState extends State<SavedStoresScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Review> _saved = [];

  @override
  void initState() {
    super.initState();
    _fetchSaved();
  }

  Future<void> _fetchSaved() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final savedRows = await _supabase
          .from('review_saves')
          .select('review_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final s = List<Map<String, dynamic>>.from(savedRows);
      final ids = s.map((e) => (e['review_id'] ?? '').toString()).where((v) => v.isNotEmpty).toList();

      if (ids.isEmpty) {
        if (mounted) setState(() {
          _saved = [];
          _isLoading = false;
        });
        return;
      }

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

      if (mounted) setState(() {
        _saved = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('저장한 매장 로드 실패: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("저장한 매장", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _saved.isEmpty
          ? const Center(
        child: Text(
          "아직 저장한 매장이 없습니다.",
          style: TextStyle(color: Color(0xFF6B6B6F)),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchSaved,
        color: const Color(0xFF8A2BE2),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: _saved.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final r = _saved[index];
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
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAEAEB2)),
              ),
            );
          },
        ),
      ),
    );
  }
}
