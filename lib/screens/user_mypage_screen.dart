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
import 'package:needsfine_app/screens/banner_management_screen.dart';
import 'package:needsfine_app/screens/report_management_screen.dart'; // ✅ 신고 관리 화면 임포트 (파일이 없으면 생성 필요)

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

  // ✅ NeedsFine 디자인 컬러
  final Color _backgroundColor = const Color(0xFFF2F2F7); // iOS 스타일 연회색 배경
  final Color _cardColor = Colors.white;
  final Color _primaryColor = const Color(0xFF8A2BE2);

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

  // ✅ [디자인 수정] 고객센터 모달 스타일 업그레이드
  void _showCustomerService(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // 배경 투명으로 해서 라운딩 처리
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.headset_mic_rounded, color: Color(0xFF8A2BE2), size: 28),
                    const SizedBox(width: 10),
                    Text(l10n.customerCenter, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 24),
                _ModalButton(
                  icon: Icons.rate_review_outlined,
                  text: l10n.sendSuggestion,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionWriteScreen()));
                  },
                ),
                const SizedBox(height: 12),
                _ModalButton(
                  icon: Icons.email_outlined,
                  text: l10n.inquiry,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const InquiryWriteScreen()));
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(l10n.myFine, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NotificationBadge(onTap: () => Navigator.pushNamed(context, '/notifications')),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black, size: 26),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoEditScreen()))
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: _primaryColor,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // 1. 프로필 헤더 (배경 흰색)
            Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 28),
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildProfileHeader(context, l10n)
            ),

            // 2. 메뉴 섹션 (카드형 디자인)
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
          const SizedBox(height: 10),
          Stack(
            children: [
              CircleAvatar(radius: 48, backgroundImage: profileImage, backgroundColor: Colors.grey[100]),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[200]!)),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(_userProfile!.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(_userProfile!.introduction, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(
                  icon: Icons.star_rounded,
                  label: "${l10n.needsFine} ${_avgNeedsFineScore.toStringAsFixed(1)}",
                  color: const Color(0xFF8A2BE2)
              ),
              const SizedBox(width: 10),
              _StatBadge(
                  icon: Icons.verified_user_rounded,
                  label: "${l10n.reliability} $_avgTrustLevel%",
                  color: Colors.blueAccent
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FollowStat(label: l10n.follower, count: _userProfile!.followerCount, onTap: () {}),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                _FollowStat(label: l10n.following, count: _userProfile!.followingCount, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(l10n.editProfile, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
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
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    shadowColor: Colors.transparent,
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

  // ✅ [디자인 수정] 섹션별 카드 형태로 변경
  Widget _buildMenuSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 1. 나의 활동
          _MenuSectionCard(
            title: "나의 활동",
            children: [
              _MenuItem(
                  icon: Icons.bookmark_rounded,
                  iconColor: const Color(0xFFFF6B6B),
                  title: l10n.reviewCollection,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewCollectionScreen()))
              ),
              _MenuItem(
                  icon: Icons.list_alt_rounded,
                  iconColor: const Color(0xFF4ECDC4),
                  title: l10n.myOwnList,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListsScreen()))
              ),
              _MenuItem(
                  icon: Icons.restaurant_menu_rounded,
                  iconColor: const Color(0xFFFFBE0B),
                  title: l10n.myTaste,
                  isLast: true,
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const TasteSelectionScreen()));
                    _fetchUserData();
                  }
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 고객 지원
          _MenuSectionCard(
            title: "고객 지원",
            children: [
              _MenuItem(
                  icon: Icons.headset_mic_rounded,
                  iconColor: _primaryColor,
                  title: l10n.customerCenter,
                  onTap: () => _showCustomerService(context)
              ),
              _MenuItem(
                  icon: Icons.campaign_rounded,
                  iconColor: const Color(0xFF3D3D3D),
                  title: l10n.notice,
                  isLast: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen()))
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ✅ 3. 관리자 메뉴 (관리자일 때만 표시)
          if (_isAdmin)
            _MenuSectionCard(
              title: l10n.adminMenu,
              borderColor: Colors.red.withOpacity(0.3),
              children: [
                _MenuItem(
                    icon: Icons.dashboard_rounded,
                    iconColor: Colors.blueGrey,
                    title: "관리자 대시보드",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))
                ),
                _MenuItem(
                    icon: Icons.view_carousel_rounded, // 배너 아이콘
                    iconColor: Colors.orange,
                    title: "배너 관리",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BannerManagementScreen()))
                ),
                // ✅ [추가] 신고 관리 메뉴
                _MenuItem(
                    icon: Icons.gavel_rounded, // 신고/제재 아이콘
                    iconColor: Colors.redAccent,
                    title: "신고 관리",
                    isLast: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportManagementScreen()))
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ✅ [추가] 모달 버튼 위젯
class _ModalButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ModalButton({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// ✅ [수정] 카드형 섹션 위젯
class _MenuSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? borderColor;

  const _MenuSectionCard({required this.title, required this.children, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ✅ [수정] 메뉴 아이템 스타일 개선
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : const BorderRadius.vertical(top: Radius.circular(20)), // 첫 번째 아이템 라운딩 처리는 컨테이너가 함
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE5E5EA), size: 18),
                ],
              ),
            ),
            if (!isLast)
              const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF2F2F7)),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
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
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}