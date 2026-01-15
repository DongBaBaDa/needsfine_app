import 'package:flutter/material.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("피드"),
        actions: [
          // ✅ 더미 제거 (unreadCount 0)
          NotificationBadge(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: const Center(
        child: Text("리뷰 공유 피드 화면 (준비중)"),
      ),
    );
  }
}