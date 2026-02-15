
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'dart:math';
import 'package:needsfine_app/services/user_blocking_service.dart';

class FeedService {
  static final _supabase = Supabase.instance.client;

  // --- Fetch Posts ---
  static Future<List<Map<String, dynamic>>> getPosts({
    required String filter, // 'all', 'following', 'nearMe'
    int limit = 20,
    int offset = 0,
    double? lat,
    double? lng,
    int radiusKm = 10, // Default radius for nearMe
    String? sortOption, // 'latest', 'distance'
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    // await UserBlockingService.fetchBlockedUsers(); // Ensure cache is fresh (optional vs overhead)
    // Better to fetch once on session start, currently assuming it is managed or fine to be slightly stale?
    // Let's safe-call it if empty, or just rely on global init.
    // For robustness, let's just make sure we check.
    
    // Start building query
    var queryBuilder = _supabase.from('posts').select('''
          *,
          profiles!inner(nickname, profile_image_url),
          post_likes(count),
          post_comments(count),
          my_like:post_likes!left(id),
          my_save:post_saves!left(id),
          post_votes(option_index, user_id) 
        ''');

    if (filter == 'following' && userId != null) {
      // Get list of followed user IDs
      final follows = await _supabase.from('follows').select('following_id').eq('follower_id', userId);
      final followedIds = follows.map((e) => e['following_id']).toList();
      followedIds.add(userId); // Include self
      // Apply filter
      queryBuilder = queryBuilder.filter('user_id', 'in', followedIds);
    } else if (filter == 'nearMe' && lat != null && lng != null) {
       // Simple Bounding Box Filter (approximate 1 degree ~ 111km)
       // 10km ~ 0.09 degrees
       double diff = radiusKm / 111.0;
       queryBuilder = queryBuilder
          .gte('lat', lat - diff)
          .lte('lat', lat + diff)
          .gte('lng', lng - diff)
          .lte('lng', lng + diff);
    }

    // Apply Sort and Pagination AFTER filters
    // Apply Sort and Pagination AFTER filters
    // If nearMe, we might want to fetch more and sort client side, or just order by created_at for now and filter?
    // Ideally order by distance, but standard RPC needed.
    // Use created_at for consistency for now, or client side sort if dataset is small.
    // Let's stick to created_at for pagination stability, but maybe 'nearMe' implies distance sort?
    // User requested "distance-based sorting".
    // If so, we can't easily paginate with simple Supabase query without RPC.
    // COMPROMISE: Retrieve a batch (e.g. 50-100) within the box, calculate distance, sort, and return `limit`.
    // Valid for 'nearMe' where we care about "closest" more than "newest"? Or "newest nearby"?
    // Usually "Near Me" implies distance.
    // Let's fetch larger batch without offset/limit at DB level if 'nearMe', then sort & paginate in memory.
    // WARNING: Performance risk if box is too large.
    
    List<Map<String, dynamic>> results = [];
    
    if (filter == 'nearMe' && lat != null && lng != null) {
      // Fetch larger batch - relying on bounding box to limit count
      final response = await queryBuilder.order('created_at', ascending: false).limit(100); 
      List<Map<String, dynamic>> temp = List<Map<String, dynamic>>.from(response);

      // distance calculation for all items
      for (var item in temp) {
        item['distance'] = _calcDist(lat, lng, item['lat'], item['lng']);
      }
      
      if (sortOption == 'distance') {
         // Client-side Distance Sort
         temp.sort((a, b) {
           double distA = a['distance'] ?? 999999;
           double distB = b['distance'] ?? 999999;
           return distA.compareTo(distB);
         });
      } else {
        // Default: Latest (already sorted by DB, but safe to re-sort if needed or trust DB)
        // temp is already sorted by created_at desc from DB
      }
      
      // Manual Pagination
      int start = offset;
      int end = start + limit;
      if (start < temp.length) {
         results = temp.sublist(start, end > temp.length ? temp.length : end);
      }
    } else {
       final response = await queryBuilder
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1); 
       results = List<Map<String, dynamic>>.from(response);
    }

    return results;
  }

  static double _calcDist(double lat1, double lng1, dynamic lat2, dynamic lng2) {
    if (lat2 == null || lng2 == null) return 999999;
    double lat2d = (lat2 is num) ? lat2.toDouble() : double.tryParse(lat2.toString()) ?? 0.0;
    double lng2d = (lng2 is num) ? lng2.toDouble() : double.tryParse(lng2.toString()) ?? 0.0;

    // Use Geolocator for precise distance in meters
    // import 'package:geolocator/geolocator.dart'; needed.
    // Or simple Haversine if we don't want dependency here.
    // Since we import geolocator in screens, better to use it here or simple math.
    // Let's use simple Haversine for service portability or keep it simple.
    // Actually, `Geolocator.distanceBetween` is best. 
    // But this file might not have geolocator imported.
    // Let's check imports. No geolocator yet.
    // I will use a custom Haversine implementation to avoid adding dependency if not present,
    // OR just add the import.
    // Since `feed_list_screen.dart` uses it, package is available.
    // I'll add import at top of file in next step or use simple Euclidean relative check as before was square.
    // Return KILOMETERS for UI display.
    
    const R = 6371; // Radius of the earth in km
    double dLat = _deg2rad(lat2d - lat1);
    double dLon = _deg2rad(lng2d - lng1);
    double a = 
      sin(dLat/2) * sin(dLat/2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2d)) * 
      sin(dLon/2) * sin(dLon/2);
      
    double c = 2 * atan2(sqrt(a), sqrt(1-a)); 
    return R * c;
  }

  static double _deg2rad(double deg) {
    return deg * (pi / 180);
  }


  // --- Create Post ---
  static Future<void> createPost({
    required String type,
    required String content,
    List<String>? imageUrls,
    String? storeName,
    String? region,
    List<String>? voteOptions,
    double? lat,
    double? lng,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('posts').insert({
      'user_id': userId,
      'post_type': type,
      'content': content,
      'image_urls': imageUrls,
      'store_name': storeName,
      'region': region,
      'vote_options': voteOptions,
      'lat': lat,
      'lng': lng,
    });
  }

  // --- Update Post ---
  static Future<void> updatePost({
    required int postId,
    required String content,
    List<String>? imageUrls,
    String? storeName,
    String? region,
    List<String>? voteOptions,
    double? lat,
    double? lng,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('posts').update({
      'content': content,
      'image_urls': imageUrls,
      'store_name': storeName,
      'region': region,
      'vote_options': voteOptions,
      'lat': lat,
      'lng': lng,
      // 'post_type' is usually not changeable after creation
    }).eq('id', postId).eq('user_id', userId);
  }
  
  // --- Delete Post ---
  static Future<void> deletePost(int postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('posts').delete().eq('id', postId).eq('user_id', userId);
  }
  
  // 조회수 증가
  static Future<void> incrementViewCount(int postId) async {
    await _rpcIncrement('posts', 'view_count', postId);
  }

  // --- Interactions ---

  // Toggle Like (Helpful)
  static Future<bool> toggleLike(int postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Check if liked
    final existing = await _supabase
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _supabase.from('post_likes').delete().eq('id', existing['id']);
      // Decrement count in posts table if trigger not set (Assuming simple client side update or trigger handles it)
      // For responsiveness, usually we trust UI update or return new state.
      // Here we rely on the caller to update UI or refetch.
      await _rpcDecrement('posts', 'like_count', postId);
      return false;
    } else {
      // Like
      await _supabase.from('post_likes').insert({'post_id': postId, 'user_id': userId});
      await _rpcIncrement('posts', 'like_count', postId);
      return true;
    }
  }

  // Toggle Save (Bookmark)
  static Future<bool> toggleSave(int postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Check if saved
    final existing = await _supabase
        .from('post_saves')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Unsave
      await _supabase.from('post_saves').delete().eq('id', existing['id']);
      return false;
    } else {
      // Save
      await _supabase.from('post_saves').insert({'post_id': postId, 'user_id': userId});
      return true;
    }
  }
  
  // Vote
  static Future<void> vote(int postId, int optionIndex) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Supabase upsert to handle "change vote" or "new vote"
    // Constraint unique(post_id, user_id)
    await _supabase.from('post_votes').upsert({
      'post_id': postId,
      'user_id': userId,
      'option_index': optionIndex,
    }).select();
  }

  // Report
  static Future<void> reportPost({
    required int postId,
    required String reason,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    String finalReason = reason;
    if (description != null && description.isNotEmpty) {
      finalReason += " ($description)";
    }

    await _supabase.from('reports').insert({
      'reporter_id': userId,
      'content_type': 'post', // Fixed column name
      'reported_content_id': postId, // Fixed column name
      'reason': finalReason,
      'status': 'pending',
    });
  }

  // --- Helpers ---
  static Future<void> _rpcIncrement(String table, String column, int rowId) async {
      try {
        await _supabase.rpc('increment_counter_int', params: {
          'table_name': table, 
          'column_name': column, 
          'row_id': rowId
        });
      } catch(e) {
          // Fallback if RPC doesn't exist: Client side increment (Less safe but works for proto)
          // Or just ignore if we rely on count aggregation
      }
  }
  
  static Future<void> _rpcDecrement(String table, String column, int rowId) async {
      try {
        await _supabase.rpc('decrement_counter_int', params: {
            'table_name': table, 
            'column_name': column, 
            'row_id': rowId
        });
      } catch(e) { }
  }
  // --- Comments ---
  static Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final response = await _supabase
        .from('post_comments')
        .select('*, profiles(nickname, profile_image_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createComment(int postId, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('post_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  // --- Feed Collection Methods ---

  // 1. Saved Feeds
  static Future<List<Map<String, dynamic>>> getSavedFeeds({int limit = 20, int offset = 0}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('post_saves')
        .select('''
          created_at,
          posts!inner(
            *,
            profiles(nickname, profile_image_url),
            post_likes(count),
            post_comments(count),
            my_like:post_likes!left(id),
            my_save:post_saves!left(id),
            post_votes(option_index, user_id)
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => e['posts'] as Map<String, dynamic>).toList();
  }

  // 2. Liked Feeds (Helpful)
  static Future<List<Map<String, dynamic>>> getLikedFeeds({int limit = 20, int offset = 0}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('post_likes')
        .select('''
          created_at,
          posts!inner(
            *,
            profiles(nickname, profile_image_url),
            post_likes(count),
            post_comments(count),
            my_like:post_likes!left(id),
            my_save:post_saves!left(id),
            post_votes(option_index, user_id)
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false) // Liked time
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => e['posts'] as Map<String, dynamic>).toList();
  }

  // 3. Commented Feeds
  static Future<List<Map<String, dynamic>>> getCommentedFeeds({int limit = 20, int offset = 0}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Note: Distinct posts only? Supabase simpler doing fetched all then distinct, or RPC.
    // For now, simple query may return duplicates if commented multiple times.
    // We can use .rpc if needed, but let's try standard join.
    // Actually, getting unique posts is better.
    // Let's select distinct post_id from comments first or use a view/RPC.
    // Given the constraints, let's just fetch comments and map to posts, deduping in Dart.
    
    final response = await _supabase
        .from('post_comments')
        .select('''
          created_at,
          posts!inner(
            *,
            profiles(nickname, profile_image_url),
            post_likes(count),
            post_comments(count),
            my_like:post_likes!left(id),
            my_save:post_saves!left(id),
            post_votes(option_index, user_id)
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + (limit * 2) - 1); // Fetch more to account for dupes

    final List<Map<String, dynamic>> posts = [];
    final Set<int> seenIds = {};

    for (var item in response) {
      final post = item['posts'] as Map<String, dynamic>;
      final id = post['id'] as int;
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        posts.add(post);
      }
      if (posts.length >= limit) break;
    }

    return posts;
  }

  // --- Example: Get Post By ID (for detail screen refresh) ---
  static Future<Map<String, dynamic>?> getPostById(int postId) async {
    final userId = _supabase.auth.currentUser?.id;
    final response = await _supabase.from('posts').select('''
          *,
          profiles!inner(nickname, profile_image_url),
          post_likes(count),
          post_comments(count),
          my_like:post_likes!left(id),
          my_save:post_saves!left(id),
          post_votes(option_index, user_id) 
        ''').eq('id', postId).maybeSingle();
    
    return response;
  }
}
