import 'package:flutter/material.dart';
import '../core/needsfine_theme.dart';
import '../models/user_model.dart';
import 'package:needsfine_app/screens/follow_list_screen.dart'; // ✅ 임포트 추가
import 'dart:io';

class MyFeedScreen extends StatelessWidget {
  final UserProfile userProfile;
  final List<dynamic> reviews;

  const MyFeedScreen({
    super.key,
    required this.userProfile,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("프로필"),
        centerTitle: true,
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
            Divider(thickness: 8, color: kNeedsFinePurpleLight),
            _buildReviewSection(context),
          ],
        ),
      ),
    );
  }

  // 1. 내 정보가 반영된 프로필 헤더
  Widget _buildProfileHeader(BuildContext context) {
    ImageProvider profileImage;
    if (userProfile.imageFile != null) {
      profileImage = FileImage(userProfile.imageFile!);
    } else if (userProfile.profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(userProfile.profileImageUrl);
    } else {
      profileImage = const AssetImage('assets/images/default_profile.png');
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: kNeedsFinePurpleLight,
                backgroundImage: profileImage,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userProfile.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // ✅ 클릭 가능하도록 GestureDetector 추가
                      GestureDetector(
                        onTap: () => _navigateToFollowList(context, 0),
                        child: Text("팔로워 ${userProfile.followerCount}", style: const TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _navigateToFollowList(context, 1),
                        child: Text("팔로잉 ${userProfile.followingCount}", style: const TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          _buildInfoRow("평균 별점", "5.0", isStar: true),
          const SizedBox(height: 14),
          _buildInfoRow("신뢰도", "${userProfile.reliability}%", isReliability: true),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: kNeedsFinePurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("+ 팔로우", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ✅ 팔로우 리스트 화면으로 이동하는 헬퍼 함수
  void _navigateToFollowList(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListScreen(
          userId: "현재_피드_주인의_ID", // 실제 구현 시 userProfile에 ID 필드를 추가하여 연동하세요.
          nickname: userProfile.nickname,
          initialTabIndex: tabIndex,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStar = false, bool isReliability = false}) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        if (isStar) ...[
          const SizedBox(width: 6),
          ...List.generate(5, (index) => const Icon(Icons.star, color: Colors.orange, size: 18)),
        ],
        if (isReliability) ...[
          const SizedBox(width: 6),
          const Icon(Icons.verified_user, color: kNeedsFinePurple, size: 18),
        ]
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text("${userProfile.nickname} 님의 리뷰 ${reviews.length}개",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
          const SizedBox(height: 20),

          if (reviews.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text("아직 작성된 리뷰가 없습니다.", style: TextStyle(color: Colors.grey)),
            ))
          else
            ...reviews.map((review) => _buildReviewCard(context, review)).toList(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: kNeedsFinePurpleLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.restaurant, color: kNeedsFinePurple, size: 22),
          ),
          title: Text(review['restaurant_name'] ?? "식당명", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${review['category'] ?? '음식'} · ${review['location'] ?? '위치'}"),
          onTap: () {},
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: List.generate(4, (index) => _buildPlaceholder()),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  Text(" ${review['rating'] ?? '5.0'}  ·  ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.grey),
                  Text(" ${review['visit_time'] ?? '방문'} ", style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  const Text("6일 전", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review['content'] ?? "정말 맛있게 먹었습니다!",
                style: const TextStyle(height: 1.5, fontSize: 15),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildPlaceholder() => Container(color: kNeedsFinePurpleLight, child: const Icon(Icons.image, color: Colors.white));

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userProfile.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                _modalAction(context, "내 리뷰 숨기기", Colors.black87, Icons.visibility_off_outlined),
                _modalAction(context, "내 피드 공유", kNeedsFinePurple, Icons.share_outlined),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modalAction(BuildContext context, String title, Color color, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: () => Navigator.pop(context),
    );
  }
}