import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/my_taste_screen.dart';
import 'package:needsfine_app/screens/myfeed_screen.dart';
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
  final _supabase = Supabase.instance.client;
  UserProfile? _userProfile;
  List<dynamic> _myReviews = []; // ✅ 리뷰 리스트를 담을 변수 추가
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // ✅ 프로필과 리뷰를 동시에 가져오도록 통합
  }

  // 서버에서 프로필 및 리뷰 정보를 가져오는 함수
  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. 프로필 정보 가져오기
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // 2. 리뷰 정보 가져오기 (reviews 테이블 이름 확인 필요)
      final reviewData = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (profileData != null && mounted) {
        setState(() {
          _userProfile = UserProfile(
            nickname: profileData['nickname'] ?? "이름 없음",
            introduction: profileData['introduction'] ?? "자신을 알릴 수 있는 소개글을 작성해 주세요.",
            activityZone: profileData['activity_zone'] ?? "활동 지역 미설정",
            profileImageUrl: profileData['profile_image_url'] ?? "",
            reliability: profileData['reliability'] ?? 0,
            followerCount: profileData['follower_count'] ?? 0,
            followingCount: profileData['following_count'] ?? 0,
          );
          _myReviews = reviewData; // ✅ 리뷰 리스트 저장
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateAndEditProfile() async {
    if (_userProfile == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditScreen(userProfile: _userProfile!)),
    );
    _fetchUserData(); // 수정 후 데이터 갱신
  }

  void _showCustomerService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFDF9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("고객센터", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _customerOption(Icons.help_outline, "자주 묻는 질문(FAQ)"),
              _customerOption(Icons.chat_bubble_outline, "1:1 채팅 상담"),
              _customerOption(Icons.mail_outline, "이메일 문의하기"),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: kNeedsFinePurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_userProfile == null) return const Scaffold(body: Center(child: Text("사용자 정보를 찾을 수 없습니다.")));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: const Text("마이페이지"),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoEditScreen()))
          )
        ],
      ),
      body: ListView(
        children: [
          _buildProfileHeader(context),
          const Divider(thickness: 8, color: kNeedsFinePurpleLight),
          _buildMenuListItem(
              icon: Icons.restaurant_menu,
              title: "나의 입맛",
              isPoint: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTasteScreen()))
          ),
          _buildMenuListItem(
              icon: Icons.support_agent,
              title: "고객센터",
              onTap: () => _showCustomerService(context)
          ),
          _buildMenuListItem(icon: Icons.notifications_none, title: "공지사항", onTap: () {}),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImage,
                  backgroundColor: kNeedsFinePurpleLight,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userProfile!.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kNeedsFinePurpleLight, borderRadius: BorderRadius.circular(12)),
                      child: Text("신뢰도 ${_userProfile!.reliability}%", style: const TextStyle(color: kNeedsFinePurple, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("소개", style: TextStyle(fontSize: 12, color: kNeedsFinePurple, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_userProfile!.introduction, style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildInfoBox(title: "팔로워", value: "${_userProfile!.followerCount}")),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoBox(title: "팔로잉", value: "${_userProfile!.followingCount}")),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _navigateAndEditProfile,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kNeedsFinePurple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("프로필 수정", style: TextStyle(color: kNeedsFinePurple)),
            ),
          ),
          const SizedBox(height: 10),

          // ✅ [수정된 부분] 나의 피드로 이동할 때 데이터(userProfile, reviews)를 넘겨줍니다.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyFeedScreen(
                          userProfile: _userProfile!,
                          reviews: _myReviews, // ✅ 서버에서 가져온 리뷰 리스트 전달
                        )
                    )
                );
              },
              child: const Text("나의 피드", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kNeedsFinePurpleLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMenuListItem({required IconData icon, required String title, required VoidCallback onTap, bool isPoint = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: isPoint ? kNeedsFinePurple : Colors.black87),
      title: Text(title, style: TextStyle(fontWeight: isPoint ? FontWeight.bold : FontWeight.normal, color: isPoint ? kNeedsFinePurple : Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}