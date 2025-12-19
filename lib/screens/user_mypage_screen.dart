import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'profile_edit_screen.dart';
import 'info_edit_screen.dart';
import 'follow_list_screen.dart'; // 팔로우 리스트 화면 import
import 'dart:math';

class UserMyPageScreen extends StatefulWidget {
  const UserMyPageScreen({super.key});

  @override
  State<UserMyPageScreen> createState() => _UserMyPageScreenState();
}

class _UserMyPageScreenState extends State<UserMyPageScreen> {
  late UserProfile _userProfile;

  @override
  void initState() {
    super.initState();
    _userProfile = UserProfile(
      nickname: "니즈파인",
      title: "맛잘알🔥",
      level: 1,
      currentExp: 0,
      maxExp: 100,
      introduction: "'안녕하세요', '니즈파인입니다'.",
      influence: 2300,
      points: 17231,
      profileImagePath: null,
    );
  }

  Future<void> _navigateAndEditProfile() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
  }
  
  void _navigateToFollowList() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const FollowListScreen()));
  }

  void _goToPlaceholderPage(String title) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text("$title 화면 (추후 개발 예정)")))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("마이파인"),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoEditScreen())))
        ],
      ),
      body: ListView(
        children: [
          _buildProfileHeader(context),
          _buildSelfIntroduction(_userProfile.introduction),
          const SizedBox(height: 20),
          _buildInfoBoxes(context),
          const Divider(thickness: 8, color: Color(0xFFF0F0F0)),
          _buildReviewTop3Section(),
          const Divider(thickness: 8, color: Color(0xFFF0F0F0)),
          _buildMenuListItem(icon: Icons.restaurant_menu, title: "나의 입맛", onTap: () => Navigator.pushNamed(context, '/mytaste')),
          _buildMenuListItem(icon: Icons.payment, title: "결제관리", onTap: () => _goToPlaceholderPage("결제관리")),
          _buildMenuListItem(icon: Icons.support_agent, title: "고객센터", onTap: () => _goToPlaceholderPage("고객센터")),
          _buildMenuListItem(icon: Icons.event, title: "이벤트", onTap: () => _goToPlaceholderPage("이벤트")),
          _buildMenuListItem(icon: Icons.policy_outlined, title: "약관 및 정책", onTap: () => _goToPlaceholderPage("약관 및 정책")),
          _buildMenuListItem(icon: Icons.settings, title: "설정", onTap: () => _goToPlaceholderPage("설정")),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userProfile.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                     Row(children: [
                        Text("신뢰도 94%", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Text("상위 1% 판별사", style: TextStyle(color: Colors.grey)),
                     ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _navigateAndEditProfile, child: const Text("프로필 변경"))
        ],
      ),
    );
  }

  Widget _buildSelfIntroduction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
    );
  }

  Widget _buildInfoBoxes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildInfoBox(title: "나의 구독자", value: "${_userProfile.influence}명", onTap: _navigateToFollowList)),
          const SizedBox(width: 16),
          Expanded(child: _buildInfoBox(title: "마이 포인트", value: "${_userProfile.points} P", onTap: () {})),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String title, required String value, required VoidCallback onTap,}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewTop3Section() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("내 리뷰 Top 3", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("+ 더보기")]),
          const SizedBox(height: 12),
          _buildReviewItem("인생 맛집 찾았다", "신뢰도 98점", 102, true),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String title, String subtitle, int likes, bool highTrust) {
     return ListTile(leading: Icon(Icons.rate_review, color: highTrust ? Colors.deepPurple : Colors.grey), title: Text(title), subtitle: Text(subtitle), trailing: Text("👍 $likes"));
  }
  
  Widget _buildMenuListItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
