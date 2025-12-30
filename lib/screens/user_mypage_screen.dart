import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // [추가]
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
  final _supabase = Supabase.instance.client; // [추가]
  UserProfile? _userProfile; // [수정] 초기값 null로 설정
  bool _isLoading = true; // [추가] 로딩 상태

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // [추가] 시작 시 서버 데이터 로드
  }

  // [추가] 서버에서 프로필 정보를 가져오는 함수
  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _userProfile = UserProfile(
            nickname: data['nickname'] ?? "이름 없음",
            introduction: data['introduction'] ?? "자신을 알릴 수 있는 소개글을 작성해 주세요.",
            activityZone: data['activity_zone'] ?? "활동 지역 미설정",
            profileImageUrl: data['profile_image_url'] ?? "",
            reliability: data['reliability'] ?? 0,
            followerCount: data['follower_count'] ?? 0,
            followingCount: data['following_count'] ?? 0,
            // isAdmin 등 필요한 필드 추가 가능
          );
        });
      }
    } catch (e) {
      debugPrint("프로필 로드 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateAndEditProfile() async {
    if (_userProfile == null) return;

    // 수정 화면으로 이동하고 결과를 기다림
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(userProfile: _userProfile!),
      ),
    );

    // 수정 완료 후 돌아오면 서버 데이터를 다시 불러와서 화면 갱신
    _fetchUserProfile();
  }

  void _navigateToFollowList() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const FollowListScreen()));
  }

  void _goToPlaceholderPage(String title) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text("$title 화면 (추후 개발 예정)")))));
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 데이터가 없을 때의 처리
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_userProfile == null) return const Scaffold(body: Center(child: Text("사용자 정보를 찾을 수 없습니다.")));

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
    if (_userProfile!.imageFile != null) {
      profileImage = FileImage(_userProfile!.imageFile!);
    } else if (_userProfile!.profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(_userProfile!.profileImageUrl);
    } else {
      profileImage = const AssetImage('assets/images/default_profile.png');
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
                    Text(_userProfile!.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text("신뢰도 ${_userProfile!.reliability}%", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 자기소개 표시
          Text(_userProfile!.introduction, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInfoBox(title: "팔로워", value: "${_userProfile!.followerCount}", onTap: _navigateToFollowList)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoBox(title: "팔로잉", value: "${_userProfile!.followingCount}", onTap: _navigateToFollowList)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: _navigateAndEditProfile, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text("프로필 수정")),
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