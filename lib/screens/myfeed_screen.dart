import 'package:flutter/material.dart';
import '../core/needsfine_theme.dart';

class MyFeedScreen extends StatelessWidget {
  const MyFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back),
        title: const Text("프로필"),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            // ✅ 변수를 사용하므로 const 제거
            Divider(thickness: 8, color: kNeedsFinePurpleLight),
            _buildReviewSection(context),
          ],
        ),
      ),
    );
  }

  // 1. 프로필 상단부
  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: kNeedsFinePurpleLight,
                child: Icon(Icons.person, color: kNeedsFinePurple, size: 40),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("이주렁밭두렁", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Text("팔로워 0", style: TextStyle(color: Colors.grey)),
                      SizedBox(width: 12),
                      Text("팔로잉 0", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text("+ 팔로우"),
          ),
          const SizedBox(height: 24),
          _buildInfoRow("평균 별점", "5", isStar: true),
          const SizedBox(height: 16),
          _buildInfoRow("음식 취향", "아직 취향을 선택하지 않았어요"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStar = false}) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (isStar) ...[
          const SizedBox(width: 4),
          ...List.generate(5, (index) => const Icon(Icons.star, color: Colors.orange, size: 18)),
        ]
      ],
    );
  }

  // 2. 리뷰 피드 영역
  Widget _buildReviewSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text("이주렁밭두렁 님의 리뷰 3개", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 16),
          _buildReviewCard(context),
        ],
      ),
    );
  }

  // 3. 리뷰 카드
  Widget _buildReviewCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: kNeedsFinePurpleLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.restaurant, color: kNeedsFinePurple, size: 20),
          ),
          title: const Text("모담 서울역점", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("한식 · 서울역"),
          onTap: () {}, // ✅ onPressed가 아닌 onTap 사용
        ),
        // 이미지 그리드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: [
                _buildPlaceholder(),
                _buildPlaceholder(),
                _buildPlaceholder(),
                Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPlaceholder(),
                    Container(color: Colors.black45, child: const Center(child: Text("+4", style: TextStyle(color: Colors.white, fontSize: 20)))),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.star, color: Colors.orange, size: 18),
                  Text(" 5.0  ·  ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.grey),
                  Text(" 점심", style: TextStyle(color: Colors.grey)),
                  Spacer(),
                  Text("6일 전", style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "상견례자리여서 신경쓰였는데 정말 좋았습니다. ppt까지 준비해서 소통했는데 룸이라서 편안하게 진행할 수 있었어요. 전반적으로 간이 세지 않아 부모님도 만족해하셨습니다.",
                style: TextStyle(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() => Container(color: kNeedsFinePurpleLight);

  // 4. 바텀 시트 (차단/신고)
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("이주렁밭두렁", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              _modalAction(context, "내 리뷰 숨기기", Colors.black),
              _modalAction(context, "차단", Colors.red),
              _modalAction(context, "신고", Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _modalAction(BuildContext context, String title, Color color) {
    return ListTile(
      title: Center(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      onTap: () => Navigator.pop(context),
    );
  }
}