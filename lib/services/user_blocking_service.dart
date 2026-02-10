
import 'package:supabase_flutter/supabase_flutter.dart';

class UserBlockingService {
  static final _supabase = Supabase.instance.client;
  
  // Cache blocked user IDs to avoid repetitive DB calls
  static Set<String> _blockedUserIds = {};
  
  // Fetch and cache blocks (Call this on app start or login)
  static Future<void> fetchBlockedUsers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _blockedUserIds.clear();
      return;
    }

    try {
      final response = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', userId);
      
      _blockedUserIds = (response as List).map((e) => e['blocked_id'] as String).toSet();
    } catch (e) {
      print('Error fetching blocked users: $e');
    }
  }

  // Check if a user is blocked
  static bool isBlocked(String targetUserId) {
    return _blockedUserIds.contains(targetUserId);
  }

  // Filter list of content (Maps)
  static List<Map<String, dynamic>> filterBlockedContent(List<Map<String, dynamic>> items, String userIdKey) {
    if (_blockedUserIds.isEmpty) return items;
    return items.where((item) => !_blockedUserIds.contains(item[userIdKey])).toList();
  }

  // Add block locally (Optimistic update)
  static void addBlock(String blockedId) {
    _blockedUserIds.add(blockedId);
  }

  // Remove block locally
  static void removeBlock(String blockedId) {
    _blockedUserIds.remove(blockedId);
  }
}
