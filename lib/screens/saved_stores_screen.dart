import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class SavedStoresScreen extends StatefulWidget {
  const SavedStoresScreen({super.key});

  @override
  State<SavedStoresScreen> createState() => _SavedStoresScreenState();
}

class _SavedStoresScreenState extends State<SavedStoresScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _supabase
          .from('store_saves_distinct_view')
          .select('store_key, store_name, store_address, created_at, user_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      debugPrint('저장한 매장 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToMapWithStore(String storeName, String? address) {
    if (storeName.isEmpty) return;

    searchTrigger.value = SearchTarget(
      query: storeName,
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _removeSaved(String storeKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('store_saves')
          .delete()
          .eq('user_id', userId)
          .eq('store_key', storeKey);

      await _fetch();
    } catch (e) {
      debugPrint('저장 삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          l10n.savedStores,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetch,
        child: _items.isEmpty
            ? ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.bookmark_border_rounded,
                      size: 48, color: Color(0xFFD1D1D6)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSavedStoresHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _items[index];
            final storeKey = (item['store_key'] ?? '').toString();
            final storeName = (item['store_name'] ?? '').toString();
            final storeAddress =
            (item['store_address'] ?? '').toString();

            return InkWell(
              onTap: () => _goToMapWithStore(
                  storeName, storeAddress.isEmpty ? null : storeAddress),
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
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: Color(0xFF8A2BE2),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (storeAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              storeAddress,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFF8E8E93)),
                      onPressed: storeKey.isEmpty
                          ? null
                          : () => _removeSaved(storeKey),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
