import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import '../models/user_model.dart';

// ✅ 화면 이동을 위한 import
import 'package:needsfine_app/screens/taste_selection_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';
import 'package:needsfine_app/screens/review_collection_screen.dart';
import 'package:needsfine_app/screens/profile_edit_screen.dart';
import 'package:needsfine_app/screens/info_edit_screen.dart';
import 'package:needsfine_app/screens/notice_screen.dart';
import 'package:needsfine_app/screens/suggestion_write_screen.dart';
import 'package:needsfine_app/screens/inquiry_write_screen.dart';
import 'package:needsfine_app/screens/admin_dashboard_screen.dart';
import 'package:needsfine_app/screens/my_lists_screen.dart';
import 'package:needsfine_app/screens/banner_management_screen.dart'; // ✅ 배너 관리 화면 임포트

// ✅ 알림 뱃지 위젯
import 'package:needsfine_app/widgets/notification_badge.dart';

// ✅ 다국어 패키지 임포트
import 'package:needsfine_app/l10n/app_localizations.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
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

      final List<Review> reviewObjects = rawList.whereType<Map>().map((m) => Review.fromJson(Map<String, dynamic>.from(m))).toList();

      if (profileData != null && mounted) {
        final l10n = AppLocalizations.of(context)!;

        setState(() {
          _isAdmin = profileData['is_admin'] ?? false;
          _myTags = List<String>.from(profileData['taste_tags'] ?? []);
          _myReviews = reviewObjects;
          _userProfile = UserProfile(
            nickname: profileData['nickname'] ?? l10n.noName,
            introduction: profileData['introduction'] ?? l10n.noIntro,
            activityZone: profileData['activity_zone'] ?? l10n.unspecified,
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
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(l10n.customerCenter, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: Text(l10n.sendSuggestion),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionWriteScreen()));
                }
            ),
            ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(l10n.inquiry),
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
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_userProfile == null) return Scaffold(body: Center(child: Text(l10n.loadError)));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(l10n.myFine, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
            Container(color: Colors.white, padding: const EdgeInsets.only(bottom: 24), child: _buildProfileHeader(context, l10n)),
            const SizedBox(height: 16),
            _buildMenuSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n) {
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(
                  label: "${l10n.needsFine} ${_avgNeedsFineScore.toStringAsFixed(1)}",
                  color: const Color(0xFF8A2BE2)
              ),
              const SizedBox(width: 8),
              _StatBadge(
                  label: "${l10n.reliability} $_avgTrustLevel%",
                  color: Colors.blueAccent
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FollowStat(label: l10n.follower, count: _userProfile!.followerCount, onTap: () {}),
              Container(height: 24, width: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 30)),
              _FollowStat(label: l10n.following, count: _userProfile!.followingCount, onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),

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
                  child: Text(l10n.editProfile, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final currentUserId = _supabase.auth.currentUser?.id;
                    if (currentUserId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: currentUserId)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A2BE2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(l10n.myFeed, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _MenuItem(
              icon: Icons.bookmark_border_rounded,
              title: l10n.reviewCollection,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewCollectionScreen()))
          ),
          _MenuItem(
              icon: Icons.list_alt_rounded,
              title: l10n.myOwnList,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListsScreen()))
          ),
          _MenuItem(
              icon: Icons.restaurant_menu_rounded,
              title: l10n.myTaste,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TasteSelectionScreen()));
                _fetchUserData();
              }
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF2F2F7)),
          _MenuItem(
              icon: Icons.headset_mic_outlined,
              title: l10n.customerCenter,
              onTap: () => _showCustomerService(context)
          ),
          _MenuItem(
              icon: Icons.notifications_none_rounded,
              title: l10n.notice,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen()))
          ),
          // ✅ 관리자 메뉴 (배너 관리 추가)
          if (_isAdmin) ...[
            const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF2F2F7)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 0, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.adminMenu, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                title: "관리자 대시보드",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                isDestructive: true
            ),
            _MenuItem(
                icon: Icons.view_carousel_outlined, // 배너 아이콘
                title: "배너 관리",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BannerManagementScreen())),
                isDestructive: true
            ),
          ]
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
      leading: Icon(icon, color: iconColor, size: 22),
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