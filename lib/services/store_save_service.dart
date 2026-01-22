import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreSaveService {
  StoreSaveService(this.supabase);
  final SupabaseClient supabase;

  /// DB의 make_store_key와 동일 규칙: lower(trim) + 공백정리 + name|address sha256 hex
  String makeStoreKey(String storeName, String? storeAddress) {
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final name = norm(storeName);
    final addr = norm(storeAddress ?? '');
    final raw = '$name|$addr';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  Future<void> saveStore({
    required String userId,
    required String storeName,
    String? storeAddress,
  }) async {
    final key = makeStoreKey(storeName, storeAddress);

    await supabase.from('store_saves').upsert({
      'user_id': userId,
      'store_key': key,
      'store_name': storeName.trim(),
      'store_address': storeAddress?.trim(),
    }, onConflict: 'user_id,store_key');
  }

  Future<void> unsaveStore({
    required String userId,
    required String storeName,
    String? storeAddress,
  }) async {
    final key = makeStoreKey(storeName, storeAddress);
    await supabase
        .from('store_saves')
        .delete()
        .eq('user_id', userId)
        .eq('store_key', key);
  }

  Future<bool> isSaved({
    required String userId,
    required String storeName,
    String? storeAddress,
  }) async {
    final key = makeStoreKey(storeName, storeAddress);
    final res = await supabase
        .from('store_saves')
        .select('id')
        .eq('user_id', userId)
        .eq('store_key', key)
        .maybeSingle();
    return res != null;
  }
}
