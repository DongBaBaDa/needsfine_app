import 'package:flutter/material.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("가게 찾기"),
        actions: [
          // ✅ 더미 제거 (unreadCount 0)
          NotificationBadge(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: const Center(
        child: Text("카테고리별 가게 찾기 화면 (준비중)"),
      ),
    );
  }
}