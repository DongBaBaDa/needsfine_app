import 'package:flutter/material.dart';

// '로그인' '전' '마이페이지' 'UI'
class MyPageLoggedOut extends StatelessWidget {
  const MyPageLoggedOut({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("마이페이지")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("로그인이 필요합니다", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("니즈파인에 참여하세요!", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 32),
            _buildInfoBox(Icons.people, "팔로우/팔로워", "'나'와 '입맛'이 '비슷한' '사람'을 '찾아보세요'."),
            _buildInfoBox(Icons.person_search, "내 정보 시스템", "'칭호'와 '레벨'을 '올려' '과시'하세요."),
            _buildInfoBox(Icons.insights, "나의 영향력", "'진짜' '리뷰'로 '가짜' '5점' '매장'을 '검증'하세요."),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("로그인 / 회원가입", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // [!] 이 함수가 아까 누락되었습니다.
  Widget _buildInfoBox(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}