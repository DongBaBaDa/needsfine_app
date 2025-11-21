import 'package:flutter/material.dart';

// --- [ ✅ ✅ 3-2. '알림' '화면' ] ---
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("알림")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.campaign, color: Colors.blue),
            title: const Text("[공지] 'AI 탐정' v2.0 업데이트!"),
            subtitle: const Text("2025년 11월 13일"),
            onTap: () {
              Navigator.pushNamed(context, '/notification-detail', arguments: "공지 상세 내용...");
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add, color: Colors.green),
            title: const Text("'홍길동'님이 '팔로우'하기 '시작'했습니다."),
            subtitle: const Text("1시간 전"),
            onTap: () {
              Navigator.pushNamed(context, '/notification-detail', arguments: "홍길동님 프로필...");
            },
          ),
          ListTile(
            leading: const Icon(Icons.thumb_up, color: Colors.red),
            title: const Text("'김철수'님이 '회원'님의 '리뷰'를 '좋아합니다'."),
            subtitle: const Text("2시간 전"),
            onTap: () {
              Navigator.pushNamed(context, '/notification-detail', arguments: "리뷰 상세 내용...");
            },
          ),
        ],
      ),
    );
  }
}

// '알림' '상세' '화면' ('더미')
class NotificationDetailScreen extends StatelessWidget {
  final String message;
  const NotificationDetailScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final String msg = ModalRoute.of(context)?.settings.arguments as String? ?? message;

    return Scaffold(
      appBar: AppBar(title: const Text("알림 상세")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(msg, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}