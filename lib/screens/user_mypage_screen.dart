import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'profile_edit_screen.dart';
import 'info_edit_screen.dart';
import 'follow_list_screen.dart';
import 'dart:io';

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
      nickname: "발랄한 맛사냥꾼_53515",
      introduction: "자신을 알릴 수 있는 소개글을 작성해 주세요.",
      activityZone: "활동 지역을 자유롭게 입력해주세요.",
      reliability: 94,
      followerCount: 2300,
      followingCount: 100,
    );
  }

  Future<void> _navigateAndEditProfile() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(userProfile: _userProfile),
      ),
    );

    if (updatedProfile != null && updatedProfile is UserProfile) {
      setState(() {
        _userProfile = updatedProfile;
      });
    }
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
          const Divider(thickness: 8, color: Color(0xFFF0F0F0)),
          _buildMenuListItem(icon: Icons.restaurant_menu, title: "나의 입맛", onTap: () => Navigator.pushNamed(context, '/mytaste')),
          _buildMenuListItem(icon: Icons.policy_outlined, title: "약관 및 정책", onTap: () => _goToPlaceholderPage("약관 및 정책")),
          _buildMenuListItem(icon: Icons.support_agent, title: "고객센터", onTap: () => _goToPlaceholderPage("고객센터")),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    ImageProvider<Object> profileImage;
    if (_userProfile.imageFile != null) {
      profileImage = FileImage(_userProfile.imageFile!);
    } else if (_userProfile.profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(_userProfile.profileImageUrl);
    } else {
      profileImage = const AssetImage('assets/images/default_profile.png'); // 기본 이미지 경로 (추가 필요)
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 40, backgroundImage: profileImage),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userProfile.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                     Row(children: [
                        Text("신뢰도 ${_userProfile.reliability}%", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                     ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_userProfile.introduction, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInfoBox(title: "팔로워", value: "${_userProfile.followerCount}", onTap: _navigateToFollowList)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoBox(title: "팔로잉", value: "${_userProfile.followingCount}", onTap: _navigateToFollowList)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: _navigateAndEditProfile, child: const Text("프로필 수정"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12))), 
          )
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String title, required String value, required VoidCallback onTap,}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
  
  Widget _buildMenuListItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
