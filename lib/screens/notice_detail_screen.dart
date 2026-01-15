import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 알림 리스트에서 넘겨준 ID를 받음
    final String? noticeId = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("공지사항", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Supabase.instance.client
            .from('notices')
            .select()
            .eq('id', noticeId ?? '')
            .single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("내용을 불러올 수 없습니다."));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  data['created_at'].toString().substring(0, 10),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Divider(height: 40),
                Text(data['content'], style: const TextStyle(fontSize: 16, height: 1.6)),
              ],
            ),
          );
        },
      ),
    );
  }
}