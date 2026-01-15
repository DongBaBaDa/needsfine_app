import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback onTap;
  final Color iconColor;

  const NotificationBadge({
    super.key,
    required this.onTap,
    this.iconColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;

    if (myId == null) {
      return IconButton(
        icon: Icon(Icons.notifications_none, color: iconColor),
        onPressed: onTap,
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      // ✅ primaryKey 로 오타 수정 완료
      stream: Supabase.instance.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('is_read', false),
      builder: (context, snapshot) {
        final rawData = snapshot.data ?? [];
        final unreadCount = rawData.where((json) {
          return json['receiver_id'] == myId || json['receiver_id'] == null;
        }).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: iconColor),
              onPressed: onTap,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}