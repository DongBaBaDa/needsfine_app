import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "알림",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // ✅ primaryKey 로 오타 수정 완료
        stream: Supabase.instance.client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .limit(99),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawData = snapshot.data ?? [];
          final notifications = rawData.where((json) {
            return json['receiver_id'] == myId || json['receiver_id'] == null;
          }).map((json) => AppNotification(
            id: json['id'],
            title: json['title'],
            content: json['content'],
            createdAt: DateTime.parse(json['created_at']),
            type: NotificationType.values.byName(json['type']),
            referenceId: json['reference_id'],
            isRead: json['is_read'],
          )).toList();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("새로운 알림이 없습니다.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getIconColor(item.type).withOpacity(0.1),
                  child: Icon(_getIconData(item.type), color: _getIconColor(item.type), size: 20),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(item.content, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                trailing: Text(_formatTime(item.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                tileColor: item.isRead ? Colors.transparent : const Color(0xFFF8F5FF),
                onTap: () => _handleNotificationClick(context, item),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationClick(BuildContext context, AppNotification notification) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notification.id);

    if (!context.mounted) return;

    // ✅ 요청하신 타입별 이동 로직 수정 부분
    switch (notification.type) {
      case NotificationType.inquiry:
      // 문의 내용 상세로 이동 (참조 ID 전달)
        Navigator.pushNamed(context, '/inquiry_detail', arguments: notification.referenceId);
        break;
      case NotificationType.notice:
      // 공지사항 상세로 이동 (참조 ID 전달)
        Navigator.pushNamed(context, '/notice_detail', arguments: notification.referenceId);
        break;
      case NotificationType.follow:
      // 팔로우한 유저의 공개 프로필로 이동
        Navigator.pushNamed(context, '/public_profile', arguments: notification.referenceId);
        break;
      case NotificationType.event:
      // 이벤트 상세 페이지로 이동
        Navigator.pushNamed(context, '/event_detail', arguments: notification.referenceId);
        break;
      default:
        break;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return "${diff.inMinutes}분 전";
    if (diff.inHours < 24) return "${diff.inHours}시간 전";
    return "${time.month}/${time.day}";
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.notice: return Icons.campaign;
      case NotificationType.follow: return Icons.person_add;
      case NotificationType.comment: return Icons.chat_bubble_outline;
      case NotificationType.inquiry: return Icons.help_outline;
      case NotificationType.event: return Icons.celebration;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.notice: return Colors.orange;
      case NotificationType.follow: return Colors.blue;
      case NotificationType.comment: return Colors.green;
      case NotificationType.inquiry: return Colors.purple;
      case NotificationType.event: return Colors.pink;
    }
  }
}