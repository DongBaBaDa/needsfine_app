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
import 'package:needsfine_app/screens/feed/feed_collection_screen.dart'; // ✅ Added
import 'package:needsfine_app/screens/profile_edit_screen.dart';
import 'package:needsfine_app/screens/info_edit_screen.dart';
import 'package:needsfine_app/screens/notice_screen.dart';
import 'package:needsfine_app/screens/suggestion_write_screen.dart';
import 'package:needsfine_app/screens/inquiry_write_screen.dart';
import 'package:needsfine_app/screens/admin_dashboard_screen.dart';
import 'package:needsfine_app/screens/my_lists_screen.dart';
import 'package:needsfine_app/screens/banner_management_screen.dart';
import 'package:needsfine_app/screens/report_management_screen.dart';
import 'package:needsfine_app/screens/follow_list_screen.dart'; // ✅ 팔로우 리스트 추가
import 'package:needsfine_app/screens/onboarding/taste_survey_modal.dart';
import 'package:needsfine_app/screens/user_inquiry_history_screen.dart'; // ✅ 문의 내역 추가
import 'package:needsfine_app/screens/store_management_screen.dart'; // ✅ 매장 관리 추가
import 'package:needsfine_app/screens/request_store_registration_screen.dart'; // ✅ 매장 등록 요청 추가
import 'package:needsfine_app/screens/referral_screen.dart'; // ✅ 친구 초대 화면 추가

import 'package:needsfine_app/widgets/notification_badge.dart';
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
  int _totalHelpfulCount = 0; // ✅ [추가] 총 받은 도움 수
  bool _isSuperAdmin = false; // ✅ 슈퍼 관리자 확인

  final Color _backgroundColor = const Color(0xFFF2F2F7);
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
        int totalLikes = 0;
        final Map<String, int> tagCounts = {}; // ✅ 태그 카운트용 맵 추가

        for (final item in rawList) {
          final review = (item is Map) ? Map<String, dynamic>.from(item as Map) : <String, dynamic>{};
          totalScore += ((review['needsfine_score'] as num?) ?? 0).toDouble();
          final double trustScore = (review['trust_level'] as num?)?.toDouble() ?? 50.0;
          totalTrust += trustScore.round();
          
          // ✅ like_count 합산 (물리적 컬럼 or Relation Count)
          int likeCount = (review['like_count'] as int?) ?? 
              ((review['review_votes'] is List && (review['review_votes'] as List).isNotEmpty) 
                  ? ((review['review_votes'] as List)[0]['count'] as int? ?? 0) 
                  : 0);
          totalLikes += likeCount;
        }
        if (mounted) {
          setState(() {
            _avgNeedsFineScore = totalScore / rawList.length;
            _avgTrustLevel = (totalTrust / rawList.length).round();
            _totalHelpfulCount = totalLikes; // ✅ 값 할당
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _avgNeedsFineScore = 0.0;
            _avgTrustLevel = 0;
            _totalHelpfulCount = 0;
          });
        }
      }

      final List<Review> reviewObjects = rawList.whereType<Map>().map((m) => Review.fromJson(Map<String, dynamic>.from(m))).toList();
      
      final currentUser = _supabase.auth.currentUser;
      final email = currentUser?.email;
      // ✅ [Fix] 오타 방지를 위해 두 가지 경우 모두 허용
      final isSuperAdminCheck = (email?.trim().toLowerCase() ?? '') == 'ineedsdfine@gmail.com' || 
                                (email?.trim().toLowerCase() ?? '') == 'ineedsfine@gmail.com';

      if (mounted) {
        setState(() {
           _isSuperAdmin = isSuperAdminCheck;
        });
      }

      if (profileData != null && mounted) {
        final l10n = AppLocalizations.of(context)!;
        
        setState(() {
          _isAdmin = profileData['is_admin'] ?? false;
          _myTags = List<String>.from(profileData['taste_tags'] ?? []);
          _myReviews = reviewObjects;
          // ... (rest of simple assignment)
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

  // ✅ [New] 리뷰 재계산 (Double Confirmation)
  Future<void> _recalculateReviews() async {
    // 1차 경고
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.recalcWarningTitle),
        content: Text(AppLocalizations.of(context)!.recalcWarningContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancelAction)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.continueAction, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm1 != true) return;

    // 2차 경고
    if (!mounted) return;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.finalConfirmTitle),
        content: Text(AppLocalizations.of(context)!.finalConfirmContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancelAction)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.executeAction, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm2 != true) return;

    // API 호출
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.recalcRequesting)));

      final response = await _supabase.functions.invoke(
        'make-server-26899706/recalculate-all',
        headers: {
          'X-Admin-Password': 'needsfine2953', // 하드코딩된 어드민 키 (서버 코드와 일치)
        },
      );

      final data = response.data;

      if (data != null && data['success'] == true) {
        final version = data['logic_version'] ?? "Unknown";
        final count = data['count'] ?? 0;
        
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.recalcCompleteTitle),
            content: Text(AppLocalizations.of(context)!.recalcCompleteContent(count, version)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.confirmAction)),
            ],
          ),
        );
      } else {
        throw Exception(data?['error'] ?? "Unknown Error");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.processFailed(e.toString())), backgroundColor: Colors.red));
    }
  }

  void _showCustomerService(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                    Text(AppLocalizations.of(context)!.customerCenter, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 24),
                _ModalButton(
                  icon: Icons.email_outlined,
                  text: AppLocalizations.of(context)!.inquiry,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const InquiryWriteScreen()));
                  },
                ),
                const SizedBox(height: 12),
                _ModalButton(
                  icon: Icons.rate_review_outlined,
                  text: AppLocalizations.of(context)!.sendSuggestion,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SuggestionWriteScreen()));
                  },
                ),
                const SizedBox(height: 12),
                _ModalButton(
                  icon: Icons.history_rounded,
                  text: l10n.inquiryHistory,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserInquiryHistoryScreen()));
                  },
                ),
                const SizedBox(height: 12),
                _ModalButton(
                  icon: Icons.store_mall_directory_rounded,
                  text: l10n.requestStoreRegistration,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RequestStoreRegistrationScreen()));
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
            Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 28),
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildProfileHeader(context, l10n)
            ),
            
            /*
            // ✅ [New] Taste Summary Section
            if (_myTags.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.myTasteSummary, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                             showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => TasteSurveyModal(onCompleted: () {
                                  Navigator.pop(context);
                                  _fetchUserData(); // Refresh data
                                }),
                              );
                          }, 
                          child: Text(l10n.analyzeAgain, style: const TextStyle(fontSize: 12, color: Color(0xFFC87CFF))),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _myTags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text("#$tag", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              */
              


            _buildMenuSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
              _userProfile!.profileImageUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 48,
                      backgroundImage: CachedNetworkImageProvider(_userProfile!.profileImageUrl),
                      backgroundColor: Colors.grey[100],
                    )
                  : CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, size: 48, color: Colors.grey),
                    ),
          const SizedBox(height: 16),
          Text(_userProfile!.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(_userProfile!.introduction, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 18),

          // ✅ [Restore] NeedsFine Score & Trust Score
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatBadge(
                      label: "${l10n.needsFineScore} ${_avgNeedsFineScore.toStringAsFixed(1)}",
                      color: const Color(0xFF8A2BE2)
                  ),
                  const SizedBox(width: 10),
                  _StatBadge(
                      label: "${l10n.trustScore} $_avgTrustLevel%",
                      color: Colors.blueAccent
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ✅ Stats Row (Review / Total Views / Helpful)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
            children: [
              _buildSimpleStat(l10n.myReviews, "${_myReviews.length}"),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              // ✅ [New Order] 총 조회수 (Total View Count)
              _buildSimpleStat(l10n.totalViewCount, "${_myReviews.fold(0, (sum, item) => sum + item.viewCount)}"),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              _buildSimpleStat(l10n.helpfulReviews, "$_totalHelpfulCount"),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ 팔로워/팔로잉 숫자 및 이동 로직
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FollowStat(
                    label: l10n.follower,
                    count: _userProfile!.followerCount,
                    // ✅ [수정] 내 아이디로 팔로워 리스트 이동
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FollowListScreen(
                        userId: _supabase.auth.currentUser!.id,
                        nickname: _userProfile!.nickname,
                        initialTabIndex: 0,
                      )));
                    }
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                _FollowStat(
                    label: l10n.following,
                    count: _userProfile!.followingCount,
                    // ✅ [수정] 내 아이디로 팔로잉 리스트 이동
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FollowListScreen(
                        userId: _supabase.auth.currentUser!.id,
                        nickname: _userProfile!.nickname,
                        initialTabIndex: 1,
                      )));
                    }
                ),
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

  Widget _buildSimpleStat(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _MenuSectionCard(
            title: "이벤트 & 혜택",
            borderColor: const Color(0xFF8A2BE2).withOpacity(0.3),
            children: [
              _MenuItem(
                  icon: Icons.card_giftcard_rounded,
                  iconColor: const Color(0xFF8A2BE2),
                  title: "친구 초대하고 점수 받기",
                  isLast: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()))
              ),
            ],
          ),
          const SizedBox(height: 20),

          _MenuSectionCard(
            title: l10n.myActivity,
            children: [
              _MenuItem(
                  icon: Icons.bookmark_rounded,
                  iconColor: const Color(0xFFFF6B6B),
                  title: l10n.reviewCollection,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewCollectionScreen()))
              ),
              // ✅ [추가] 피드 모아보기
              _MenuItem(
                  icon: Icons.dynamic_feed_rounded,
                  iconColor: const Color(0xFF9C7CFF),
                  title: l10n.myFeed,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedCollectionScreen()))
              ),
              _MenuItem(
                  icon: Icons.list_alt_rounded,
                  iconColor: const Color(0xFF4ECDC4),
                  title: l10n.myOwnList,
                  isLast: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListsScreen()))
              ),
            ],
          ),
          const SizedBox(height: 20),

          _MenuSectionCard(
            title: l10n.customerSupport,
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

          if (_isAdmin)
            _MenuSectionCard(
              title: l10n.adminMenu,
              borderColor: Colors.red.withOpacity(0.3),
            children: [
                _MenuItem(
                    icon: Icons.dashboard_rounded,
                    iconColor: Colors.blueGrey,
                    title: l10n.adminDashboard,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))
                ),
                _MenuItem(
                    icon: Icons.view_carousel_rounded,
                    iconColor: Colors.orange,
                    title: l10n.bannerManagement,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BannerManagementScreen()))
                ),
                _MenuItem(
                    icon: Icons.gavel_rounded,
                    iconColor: Colors.redAccent,
                    title: l10n.reportManagement,
                    isLast: !_isSuperAdmin, // 슈퍼 관리자가 아니면 여기가 마지막
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportManagementScreen()))
                ),
                if (_isSuperAdmin) 
                   _MenuItem(
                    icon: Icons.store_mall_directory_rounded,
                    iconColor: Colors.teal,
                    title: '매장 관리',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementScreen())),
                  ),
                if (_isSuperAdmin) 
                   _MenuItem(
                    icon: Icons.calculate_outlined,
                    iconColor: Colors.deepPurple,
                    title: l10n.recalculateReviews,
                    isLast: true,
                    onTap: _recalculateReviews,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

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
            : const BorderRadius.vertical(top: Radius.circular(20)),
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
  final String label;
  final Color color;
  const _StatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
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