import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import '../models/user_model.dart';

// ✅ 화면 이동을 위한 import
import 'package:needsfine_app/screens/taste_selection_screen.dart';
import 'package:needsfine_app/screens/myfeed_screen.dart';
import 'package:needsfine_app/screens/follow_list_screen.dart';
import 'package:needsfine_app/screens/review_collection_screen.dart';
import 'package:needsfine_app/screens/profile_edit_screen.dart';
import 'package:needsfine_app/screens/info_edit_screen.dart';
import 'package:needsfine_app/screens/notice_screen.dart';
import 'package:needsfine_app/screens/suggestion_write_screen.dart';
import 'package:needsfine_app/screens/inquiry_write_screen.dart';
import 'package:needsfine_app/screens/admin_dashboard_screen.dart';
import 'package:needsfine_app/screens/my_lists_screen.dart'; // ✅ [추가] 나만의 리스트 화면

// ✅ 알림 뱃지 위젯
import 'package:needsfine_app/widgets/notification_badge.dart';

class UserMyPageScreen extends StatefulWidget {
  const UserMyPageScreen({super.key});

  @override
  State<UserMyPageScreen> createState() => _UserMyPageScreenState();
}

class _UserMyPageScreenState extends State<UserMyPageScreen> {
  final _supabase = Supabase.instance.client;
  UserProfile? _userProfile;
  List<Review> _myReviews = [];
  List<String> _myTags = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  double _avgNeedsFineScore = 0.0;
  int _avgTrustLevel = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profileData = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
      final reviewData = await _supabase.from('reviews').select().eq('user_id', userId).order('created_at', ascending: false);

      final followerCountResponse = await _supabase.from('follows').count(CountOption.exact).eq('following_id', userId);
      final followingCountResponse = await _supabase.from('follows').count(CountOption.exact).eq('follower_id', userId);

      final List<dynamic> rawList = (reviewData is List) ? reviewData : <dynamic>[];

      // 평균 점수 및 신뢰도 계산
      if (rawList.isNotEmpty) {
        double totalScore = 0.0;
        int totalTrust = 0;
        for (final item in rawList) {
          final review = (item is Map) ? Map<String, dynamic>.from(item as Map) : <String, dynamic>{};
          totalScore += ((review['needsfine_score'] as num?) ?? 0).toDouble();
          totalTrust += (((review['trust_level'] as num?) ?? 0).round());
        }
        _avgNeedsFineScore = totalScore / rawList.length;
        _avgTrustLevel = (totalTrust / rawList.length).round();
      } else {
        _avgNeedsFineScore = 0.0;
        _avgTrustLevel = 0;
      }

      // 리뷰 객체 변환
      final List<Review> reviewObjects = rawList.whereType<Map>().map((m) => Review.fromJson(Map<String, dynamic>.from(m))).toList();

      if (profileData != null && mounted) {
        setState(() {
          _isAdmin = profileData['is_admin'] ?? false;
          _myTags = List<String>.from(profileData['taste_tags'] ?? []);
          _myReviews = reviewObjects;
          _userProfile = UserProfile(
            nickname: profileData['nickname'] ?? "이름 없음",
            introduction: profileData['introduction'] ?? "소개글이 없습니다.",
            activityZone: profileData['activity_zone'] ?? "지역 미설정",
            profileImageUrl: profileData['profile_image_url'] ?? "",
            reliability: _avgTrustLevel,
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

  void _showCustomerService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                }
            ),
            ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text("1:1 문의"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InquiryWriteScreen()));
                }
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
    if (_userProfile == null) return const Scaffold(body: Center(child: Text("정보를 불러올 수 없습니다.")));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("마이파인", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBadge(onTap: () => Navigator.pushNamed(context, '/notifications')),
          IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoEditScreen()))
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: const Color(0xFF8A2BE2),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Container(color: Colors.white, padding: const EdgeInsets.only(bottom: 24), child: _buildProfileHeader(context)),
            const SizedBox(height: 16),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    ImageProvider profileImage = _userProfile!.profileImageUrl.isNotEmpty
        ? CachedNetworkImageProvider(_userProfile!.profileImageUrl)
        : const AssetImage('assets/images/default_profile.png') as ImageProvider;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(radius: 45, backgroundImage: profileImage, backgroundColor: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(_userProfile!.nickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black)),
          const SizedBox(height: 8),
          Text(_userProfile!.introduction, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 16),

          // 통계 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(label: "니즈파인 ${_avgNeedsFineScore.toStringAsFixed(1)}", color: const Color(0xFF8A2BE2)),
              const SizedBox(width: 8),
              _StatBadge(label: "신뢰도 $_avgTrustLevel%", color: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 24),

          // 팔로워/팔로잉
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FollowStat(label: "팔로워", count: _userProfile!.followerCount, onTap: () {}),
              Container(height: 24, width: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 30)),
              _FollowStat(label: "팔로잉", count: _userProfile!.followingCount, onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),

          // 버튼 그룹
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditScreen(userProfile: _userProfile!)));
                    _fetchUserData();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("프로필 수정", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyFeedScreen(userProfile: _userProfile!, reviews: _myReviews)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A2BE2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("나의 피드", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _MenuItem(
              icon: Icons.bookmark_border_rounded,
              title: "리뷰 모음",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewCollectionScreen()))
          ),
          _MenuItem(
              icon: Icons.list_alt_rounded, // ✅ [추가] 나만의 리스트
              title: "나만의 리스트",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListsScreen()))
          ),
          _MenuItem(
              icon: Icons.restaurant_menu_rounded,
              title: "나의 입맛",
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TasteSelectionScreen()));
                _fetchUserData();
              }
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF2F2F7)), // ✅ 더 섬세한 구분선
          _MenuItem(
              icon: Icons.headset_mic_outlined,
              title: "고객센터",
              onTap: () => _showCustomerService(context)
          ),
          _MenuItem(
              icon: Icons.notifications_none_rounded,
              title: "공지사항",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen()))
          ),
          if (_isAdmin)
            _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                title: "관리자 메뉴",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                isDestructive: true
            ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _FollowStat extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  const _FollowStat({required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text("$count", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({required this.icon, required this.title, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1C1C1E);
    final Color iconColor  = isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF3A3A3C);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      minLeadingWidth: 28,
      leading: Icon(icon, color: iconColor, size: 22), // ✅ 네모 배경 제거(키즈/아기자기 느낌 제거)
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAEAEB2), size: 22),
    );
  }
}
