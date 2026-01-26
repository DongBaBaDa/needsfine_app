import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ 프로필 이미지 표시용
import 'package:needsfine_app/screens/email_login_screen.dart';
import 'package:needsfine_app/screens/password_change_screen.dart';
import 'package:needsfine_app/screens/terms_screen.dart';
import 'package:needsfine_app/screens/language_settings_screen.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class InfoEditScreen extends StatefulWidget {
  const InfoEditScreen({super.key});

  @override
  State<InfoEditScreen> createState() => _InfoEditScreenState();
}

class _InfoEditScreenState extends State<InfoEditScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  String _phone = '';
  String _email = '';
  String _gender = '미설정';
  bool _isNotificationOn = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _email = user.email ?? '';

      final metaGender = user.userMetadata?['gender'];
      if (metaGender != null) {
        _gender = metaGender.toString();
      }

      try {
        final data = await _supabase
            .from('profiles')
            .select('phone, gender')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          _phone = data['phone'] ?? '';
          if (data['gender'] != null && data['gender'] != '') {
            _gender = data['gender'];
          }
        }
      } catch (e) {
        debugPrint('프로필 정보 로드 실패: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EmailLoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: const Text("정말로 탈퇴하시겠습니까? 계정 정보와 활동 내역이 모두 삭제됩니다."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccount,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("회원 탈퇴 처리가 완료되었습니다.")));
      _logout();
    }
  }

  void _showPhoneAuthDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(l10n.phoneNumber,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_circle_outlined,
                  size: 48, color: Color(0xFF8A2BE2)),
              const SizedBox(height: 16),
              Text(l10n.developingMessage,
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.confirm,
                  style: const TextStyle(
                      color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCommunityGuidelines() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("커뮤니티 가이드라인",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "안전한 커뮤니티를 위해 아래 정책을 준수합니다.",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 12),
                Text("1. 부적절한 콘텐츠 금지\n"
                    "- 욕설, 비방, 혐오 발언, 성적 콘텐츠, 폭력적인 내용은 엄격히 금지되며 필터링됩니다."),
                SizedBox(height: 8),
                Text("2. 사용자 신고 및 차단\n"
                    "- 불쾌한 유저는 프로필 또는 리뷰에서 즉시 '신고' 및 '차단'할 수 있습니다.\n"
                    "- 차단 시 해당 유저의 모든 콘텐츠가 숨김 처리됩니다."),
                SizedBox(height: 8),
                Text("3. 신고 처리 정책 (24시간 내 조치)\n"
                    "- 접수된 신고는 운영팀이 24시간 이내에 검토합니다.\n"
                    "- 가이드라인 위반이 확인될 경우, 해당 콘텐츠 삭제 및 작성자 이용 제재 조치가 취해집니다.",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인",
                  style: TextStyle(
                      color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ✅ [수정] 차단한 사용자 관리 (리스트 로드 및 해제 기능)
  void _showBlockedUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // 전체 화면 활용 가능하게
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const BlockedUsersView(); // ✅ 별도 위젯으로 분리하여 상태 관리
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(l10n.settings,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 10),
          _buildSectionHeader(l10n.accountInfo),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.phone_iphone,
              label: l10n.phoneNumber,
              value: _phone.isEmpty ? l10n.verificationNeeded : _phone,
              onTap: _showPhoneAuthDialog,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.email_outlined,
              label: l10n.email,
              value: _email,
              showArrow: false,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.wc,
              label: l10n.gender,
              value: _gender == '미설정' ? l10n.unspecified : _gender,
              showArrow: false,
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(l10n.general),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.translate,
              label: l10n.languageSettings,
              value: "",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const LanguageSettingsScreen())),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(l10n.securityAndNotifications),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.lock_outline,
              label: l10n.changePassword,
              value: "",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const PasswordChangeScreen())),
            ),
            _buildDivider(),
            // ✅ 차단 사용자 관리 메뉴
            _buildSettingsItem(
              icon: Icons.block,
              label: "차단한 사용자 관리",
              value: "",
              onTap: _showBlockedUsers,
            ),
            _buildDivider(),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined,
                      size: 22, color: Colors.black87),
                  const SizedBox(width: 12),
                  Text(l10n.notificationSettings,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87)),
                  const Spacer(),
                  Switch(
                    value: _isNotificationOn,
                    activeColor: const Color(0xFF8A2BE2),
                    onChanged: (val) =>
                        setState(() => _isNotificationOn = val),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(l10n.info),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.description_outlined,
              label: l10n.termsOfService,
              value: "",
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TermsScreen())),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.shield_outlined,
              label: "커뮤니티 가이드라인 (신고 정책)",
              value: "",
              onTap: _showCommunityGuidelines,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.support_agent,
              label: l10n.inquiry,
              value: "",
              onTap: () {
                // 문의 화면 이동 로직 (생략 시 기본 팝업 등)
              },
            ),
          ]),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(l10n.logout,
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),

          const SizedBox(height: 20),
          Center(
              child: Text("${l10n.currentVersion} 1.0.0",
                  style:
                  const TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 10),

          Center(
            child: TextButton(
              onPressed: _deleteAccount,
              child: Text(
                l10n.deleteAccount,
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem(
      {required IconData icon,
        required String label,
        required String value,
        VoidCallback? onTap,
        bool showArrow = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(width: 16),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis)),
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey)
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(
      height: 1, indent: 50, endIndent: 0, color: Color(0xFFEEEEEE));
}

// ✅ [추가] 차단된 사용자 리스트 위젯 (Stateful)
class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = []; // 차단된 유저 프로필 목록

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. blocks 테이블에서 내가 차단한 ID 목록 가져오기
      final blocksData = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', myId);

      final List<dynamic> rawList = blocksData as List;
      final List<String> blockedIds = rawList.map((e) => e['blocked_id'].toString()).toList();

      if (blockedIds.isNotEmpty) {
        // 2. profiles 테이블에서 해당 ID들의 정보(닉네임, 사진) 가져오기
        // .in_() 대신 .filter()를 사용하여 버전 호환성 확보
        final profilesData = await _supabase
            .from('profiles')
            .select('id, nickname, profile_image_url')
            .filter('id', 'in', blockedIds);

        if (mounted) {
          setState(() {
            _blockedUsers = List<Map<String, dynamic>>.from(profilesData);
          });
        }
      } else {
        if (mounted) setState(() => _blockedUsers = []);
      }
    } catch (e) {
      debugPrint("차단 목록 로드 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockUser(String blockedId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase
          .from('blocks')
          .delete()
          .eq('blocker_id', myId)
          .eq('blocked_id', blockedId);

      // 리스트에서 제거하여 UI 갱신
      setState(() {
        _blockedUsers.removeWhere((user) => user['id'] == blockedId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("차단이 해제되었습니다.")),
        );
      }
    } catch (e) {
      debugPrint("차단 해제 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("차단 해제 실패")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // 높이 70%
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("차단한 사용자 관리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _blockedUsers.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("차단한 사용자가 없습니다.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                final String nickname = user['nickname'] ?? '알 수 없음';
                final String? profileUrl = user['profile_image_url'];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(profileUrl)
                        : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                  ),
                  title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: OutlinedButton(
                    onPressed: () => _unblockUser(user['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("해제"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}