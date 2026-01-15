enum NotificationType { notice, follow, comment, inquiry, event } // ✅ event 추가

class AppNotification {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final NotificationType type;
  final String? referenceId; // 상세 페이지 이동 시 필요한 ID
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.type,
    this.referenceId,
    this.isRead = false,
  });
}