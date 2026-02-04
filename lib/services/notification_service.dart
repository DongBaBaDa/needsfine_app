import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  // 1. 알림 보내기 (문의, 팔로우 등)
  static Future<void> sendNotification({
    required String receiverId,
    required NotificationType type,
    required String title,
    required String content,
    String? referenceId,
  }) async {
    await _supabase.from('notifications').insert({
      'receiver_id': receiverId,
      'type': type.name,
      'title': title,
      'content': content,
      'reference_id': referenceId,
    });
  }

  // 2. 전체 공지/이벤트 보내기 (관리자용)
  static Future<void> sendBroadcast({
    required NotificationType type,
    required String title,
    required String content,
  }) async {
    // 모든 사용자에게 보내는 로직 (Edge Function 사용 권장이나, 간단하게는 공용 receiver_id 사용)
    await _supabase.from('notifications').insert({
      'receiver_id': null, // null을 전체 공지로 약속
      'type': type.name,
      'title': title,
      'content': content,
    });
  }

  // 3. 댓글 알림 생성
  static Future<void> createCommentNotification({
    required String reviewOwnerId,
    required String commentId,
    required String commenterNickname,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      // 자기 자신의 리뷰에 댓글을 단 경우 알림 생성하지 않음
      if (currentUserId == reviewOwnerId) return;

      await _supabase.from('notifications').insert({
        'receiver_id': reviewOwnerId,
        'type': 'comment',
        'reference_id': commentId, // 댓글 ID를 reference_id에 저장
      });
    } catch (e) {
      print('댓글 알림 생성 실패: $e');
    }
  }

  // 4. 팔로우 알림 생성
  static Future<void> createFollowNotification({
    required String followedUserId,
    required String followerNickname,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase.from('notifications').insert({
        'receiver_id': followedUserId,
        'type': 'follow',
        'reference_id': currentUserId, // 팔로우한 사람의 ID를 reference_id에 저장
      });
    } catch (e) {
      print('팔로우 알림 생성 실패: $e');
    }
  }

  // 5. 실시간 알림 리스너 (Stream)
  static Stream<List<AppNotification>> getNotificationStream() {
    final myId = _supabase.auth.currentUser?.id;
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data
        .where((json) => json['receiver_id'] == myId || json['receiver_id'] == null)
        .map((json) => AppNotification(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      type: NotificationType.values.byName(json['type']),
      referenceId: json['reference_id'],
      isRead: json['is_read'],
    ))
        .toList());
  }
}