import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/taste_selection_screen.dart';
import 'package:needsfine_app/screens/myfeed_screen.dart';
import 'package:needsfine_app/screens/follow_list_screen.dart';
import 'package:needsfine_app/screens/review_collection_screen.dart'; // ✅ 새로 만들 파일 임포트
import '../models/user_model.dart';
import 'profile_edit_screen.dart';
import 'info_edit_screen.dart';
import 'notice_screen.dart';
import 'suggestion_write_screen.dart';
import 'inquiry_write_screen.dart';
import 'admin_dashboard_screen.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';

class UserMyPageScreen extends StatefulWidget {
  const UserMyPageScreen({super.key});

  @override
  State<UserMyPageScreen> createState() => _UserMyPageScreenState();
}

class _UserMyPageScreenState extends State<UserMyPageScreen> {
  final _supabase = Supabase.instance.client;
  UserProfile? _userProfile;
  List<String> _myTags = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profileData = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();

      final followerCountResponse = await _supabase.from('follows').count(CountOption.exact).eq('following_id', userId);
      final followingCountResponse = await _supabase.from('follows').count(CountOption.exact).eq('follower_id', userId);

      if (profileData != null && mounted) {
        setState(() {
          _isAdmin = profileData['is_admin'] ?? false;
          _myTags = List<String>.from(profileData['taste_tags'] ?? []);
          _userProfile = UserProfile(
            nickname: profileData['nickname'] ?? "이름 없음",
            introduction: profileData['introduction'] ?? "자신을 알릴 수 있는 소개글을 작성해 주세요.",
            activityZone: profileData['activity_zone'] ?? "활동 지역 미설정",
            profileImageUrl: profileData['profile_image_url'] ?? "",
            reliability: profileData['reliability'] ?? 0,
            followerCount: followerCountResponse,
            followingCount: followingCountResponse,
          );
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (고객센터 - 기존 코드 유지)
  void _showCustomerService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFDF9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text("고객센터", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text("건의사항 보내기"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionWriteScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text("1:1 문의 (앱 내 작성)"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const InquiryWriteScreen()));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
          NotificationBadge(onTap: () => Navigator.pushNamed(context, '/notifications')),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoEditScreen()))),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: kNeedsFinePurple,
        child: ListView(
          children: [
            _buildProfileHeader(context),
            const Divider(thickness: 8, color: kNeedsFinePurpleLight),

            // ✅ [추가] 리뷰 모음 메뉴 (나의 입맛 위에 배치)
            _buildMenuListItem(
              icon: Icons.collections_bookmark_outlined,
              title: "리뷰 모음",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReviewCollectionScreen())),
            ),

            _buildMenuListItem(
                icon: Icons.restaurant_menu,
                title: "나의 입맛",
                isPoint: true,
                onTap: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const TasteSelectionScreen()));
                  if (result == true) _fetchUserData();
                }
            ),
            _buildMenuListItem(icon: Icons.support_agent, title: "고객센터", onTap: () => _showCustomerService(context)),
            _buildMenuListItem(icon: Icons.notifications_none, title: "공지사항", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NoticeScreen()))),
            if (_isAdmin) ...[
              const Divider(thickness: 1, height: 1),
              Container(
                color: Colors.deepPurple.withOpacity(0.05),
                child: _buildMenuListItem(
                  icon: Icons.admin_panel_settings,
                  title: "소중한 피드백 (관리자)",
                  isPoint: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    ImageProvider profileImage = _userProfile!.profileImageUrl.isNotEmpty
        ? NetworkImage(_userProfile!.profileImageUrl)
        : const AssetImage('assets/images/default_profile.png') as ImageProvider;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                child: CircleAvatar(radius: 50, backgroundImage: profileImage, backgroundColor: kNeedsFinePurpleLight),
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
                    const SizedBox(height: 12),
                    if (_myTags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _myTags.take(5).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.withOpacity(0.4)), borderRadius: BorderRadius.circular(20)),
                          child: Text("#$tag", style: TextStyle(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                        )).toList(),
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
              Expanded(child: _buildStatBox("팔로워", "${_userProfile!.followerCount}", 0)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBox("팔로잉", "${_userProfile!.followingCount}", 1)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditScreen(userProfile: _userProfile!)));
                _fetchUserData();
              },
              style: OutlinedButton.styleFrom(side: const BorderSide(color: kNeedsFinePurple)),
              child: const Text("프로필 수정", style: TextStyle(color: kNeedsFinePurple)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 기존 '나의 피드' 버튼은 유지 (요구사항에 제거하란 말 없었음)
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyFeedScreen(userProfile: _userProfile!, reviews: [])));
              },
              child: const Text("나의 피드", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, int tabIndex) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => FollowListScreen(
          userId: _supabase.auth.currentUser!.id,
          nickname: _userProfile!.nickname,
          initialTabIndex: tabIndex,
        )));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: kNeedsFinePurpleLight), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNeedsFinePurple)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuListItem({required IconData icon, required String title, required VoidCallback onTap, bool isPoint = false}) {
    return ListTile(
      leading: Icon(icon, color: isPoint ? kNeedsFinePurple : Colors.black87),
      title: Text(title, style: TextStyle(color: isPoint ? kNeedsFinePurple : Colors.black87)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}