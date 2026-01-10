import 'package:flutter/material.dart';
import '../core/needsfine_theme.dart'; // ✅ 테마 변수를 쓰기 위한 임포트

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
            // ✅ 변수인 kNeedsFinePurpleLight를 쓰기 위해 앞의 const를 제거함
            Divider(thickness: 8, color: kNeedsFinePurpleLight),
            _buildReviewSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kNeedsFinePurple, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundColor: kNeedsFinePurpleLight,
                  child: Icon(Icons.person, color: kNeedsFinePurple, size: 40),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("이주렁밭두렁", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("팔로워 0  ·  팔로잉 0", style: TextStyle(color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text("+ 팔로우", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          _buildInfoRow("평균 별점", "5.0", isStar: true),
          const SizedBox(height: 16),
          _buildInfoRow("음식 취향", "아직 취향을 선택하지 않았어요"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStar = false}) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.black45))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (isStar) ...[
          const SizedBox(width: 4),
          ...List.generate(5, (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 20)),
        ]
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text("이주렁밭두렁 님의 리뷰 3개", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        _buildReviewCard(context),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kNeedsFinePurpleLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.restaurant, color: kNeedsFinePurple, size: 20),
          ),
          title: const Text("모담 서울역점", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("한식 · 서울역"),
          onTap: () {}, // ✅ ListTile은 onTap을 사용함
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: [
                Container(color: kNeedsFinePurpleLight),
                Container(color: kNeedsFinePurpleLight),
                Container(color: kNeedsFinePurpleLight),
                Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: kNeedsFinePurpleLight),
                    Container(color: Colors.black45, child: const Center(child: Text("+4", style: TextStyle(color: Colors.white, fontSize: 20)))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Center(child: Text("내 리뷰 숨기기")), onTap: () => Navigator.pop(context)),
            ListTile(title: const Center(child: Text("차단", style: TextStyle(color: Colors.red))), onTap: () => Navigator.pop(context)),
            ListTile(title: const Center(child: Text("신고", style: TextStyle(color: Colors.red))), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}