import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/screens/email_login_screen.dart';
import 'package:needsfine_app/screens/password_change_screen.dart';
import 'package:needsfine_app/screens/terms_screen.dart';
import 'package:needsfine_app/screens/language_settings_screen.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

// ✅ Added imports
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InfoEditScreen extends StatefulWidget {
  const InfoEditScreen({super.key});

  @override
  State<InfoEditScreen> createState() => _InfoEditScreenState();
}

class _InfoEditScreenState extends State<InfoEditScreen> with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  String _phone = '';
  String _email = '';
  String _gender = '미설정';
  String _birthDate = '미설정';
  
  // ✅ Notification & Version state
  bool _isNotificationEnabled = false;
  String _appVersion = '';

  // DB에 이미 저장되어 있는지 여부
  bool _isGenderSet = false;
  bool _isBirthDateSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserInfo();
    _checkNotificationPermission();
    _loadAppVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isNotificationEnabled = status.isGranted;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
      });
    }
  }

  Future<void> _toggleNotification(bool value) async {
    if (value) {
      // User wants to enable
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _isNotificationEnabled = true);
      } else if (status.isPermanentlyDenied || status.isDenied) {
        _showPermissionDialog('알림 권한 필요', '알림을 받으려면 설정에서 권한을 허용해야 합니다.');
      }
    } else {
      // User wants to disable
      _showPermissionDialog('알림 끄기', '알림을 끄려면 설정에서 권한을 해제해야 합니다.');
    }
  }

  void _showPermissionDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserInfo() async {
    // ... (existing code: _fetchUserInfo implementation)
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = _supabase.auth.currentUser;
    if (user != null) {
      _email = user.email ?? '';

      // 메타데이터 확인 (소셜 로그인 등)
      final metaGender = user.userMetadata?['gender'];
      if (metaGender != null) {
        _gender = metaGender.toString();
        _isGenderSet = true;
      }

      try {
        // DB에서 데이터 가져오기
        final data = await _supabase
            .from('profiles')
            .select('phone, gender, birth_date')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          _phone = data['phone'] ?? '';

          // 성별 데이터 확인
          if (data['gender'] != null && data['gender'] != '') {
            _gender = data['gender'];
            _isGenderSet = true;
          }

          // 생년월일 데이터 확인
          if (data['birth_date'] != null && data['birth_date'] != '') {
            try {
              DateTime parsedDate = DateTime.parse(data['birth_date']);
              _birthDate = DateFormat('yyyy년 MM월 dd일').format(parsedDate);
              _isBirthDateSet = true;
            } catch (e) {
              _birthDate = data['birth_date'];
            }
          } else {
            _birthDate = "미설정";
            _isBirthDateSet = false;
          }
        }
      } catch (e) {
        debugPrint('프로필 정보 로드 실패: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    // ... (existing code: _logout implementation)
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
    // ... (existing code: _deleteAccount implementation)
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
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) {
          throw Exception("로그인 상태가 아닙니다.");
        }

        await _supabase.from('profiles').delete().eq('id', userId);

        try {
          await _supabase.rpc('delete_user');
        } catch (rpcError) {
          debugPrint("RPC delete_user failed (may not exist): $rpcError");
        }

        await _supabase.auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("회원 탈퇴 처리가 완료되었습니다.")));
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("탈퇴 처리 중 오류: $e")));
        }
      }
    }
  }

  Future<void> _updateGender() async {
    // ... (existing code)
    final l10n = AppLocalizations.of(context)!;
    if (_isGenderSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genderOneTime)),
      );
      return;
    }

    String? selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.genderSet),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, l10n.male),
            child: Text(l10n.male),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, l10n.female),
            child: Text(l10n.female),
          ),
        ],
      ),
    );

    if (selected != null) {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      try {
        await _supabase
            .from('profiles')
            .update({'gender': selected})
            .eq('id', user.id)
            .select();

        setState(() {
          _gender = selected;
          _isGenderSet = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.saved)));
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("${l10n.saveError} $e")));
      }
    }
  }

  Future<void> _updateBirthDate() async {
    // ... (existing code)
    final l10n = AppLocalizations.of(context)!;
    if (_isBirthDateSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.birthDateOneTime)),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: l10n.birthDateSelect,
    );

    if (picked != null) {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      try {
        final int age = now.year - picked.year + 1;

        await _supabase.from('profiles').update({
          'birth_date': picked.toIso8601String(),
          'age': age,
        }).eq('id', user.id).select();

        setState(() {
          _birthDate = DateFormat('yyyy년 MM월 dd일').format(picked);
          _isBirthDateSet = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.saved)));
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("${l10n.saveError} $e")));
      }
    }
  }

  void _showPhoneAuthDialog() {
   // ... (existing code)
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
     // ... (existing code)
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(l10n.communityGuidelines,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.communityGuidelinesContent, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text("${l10n.cgItem1Title}\n- ${l10n.cgItem1Desc}"),
                const SizedBox(height: 8),
                Text("${l10n.cgItem2Title}\n- ${l10n.cgItem2Desc}"),
                const SizedBox(height: 8),
                Text("${l10n.cgItem3Title}\n- ${l10n.cgItem3Desc}",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ],
            ),
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

  void _showBlockedUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const BlockedUsersView();
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
              icon: Icons.email_outlined,
              label: l10n.email,
              value: _email,
              showArrow: false,
            ),
            _buildDivider(),
            // 성별
            _buildSettingsItem(
              icon: Icons.wc,
              label: l10n.gender,
              value: _gender == '미설정' ? l10n.genderSet : _gender,
              isSet: _isGenderSet,
              onTap: _updateGender,
              showArrow: !_isGenderSet,
            ),
            _buildDivider(),
            // 생년월일
            _buildSettingsItem(
              icon: Icons.calendar_today,
              label: l10n.birthDate,
              value: _birthDate == '미설정' ? l10n.birthDateSet : _birthDate,
              isSet: _isBirthDateSet,
              onTap: _updateBirthDate,
              showArrow: !_isBirthDateSet,
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
            _buildSettingsItem(
              icon: Icons.block,
              label: l10n.blockedUserManagement,
              value: "",
              onTap: _showBlockedUsers,
            ),
            // ✅ [Implemented] Notification Settings
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined, size: 22, color: Colors.black87),
                  const SizedBox(width: 12),
                  Text(l10n.notificationSettings, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  const Spacer(),
                  Switch(
                    value: _isNotificationEnabled,
                    activeColor: const Color(0xFF8A2BE2),
                    onChanged: _toggleNotification,
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
              label: l10n.cgTitle,
              value: "",
              onTap: _showCommunityGuidelines,
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
          // ✅ [Updated] Show only version number
          if (_appVersion.isNotEmpty)
            Center(
                child: Text("${l10n.currentVersion} $_appVersion",
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

  // ... (rest of the widgets: _buildSectionHeader, _buildSectionContainer, _buildSettingsItem, _buildDivider, BlockedUsersView)
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
        bool showArrow = true,
        bool isSet = false}) {
    final valueColor = isSet ? Colors.grey : const Color(0xFF8A2BE2);
    final valueWeight = isSet ? FontWeight.normal : FontWeight.bold;

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
                    style: TextStyle(
                        fontSize: 15,
                        color: valueColor,
                        fontWeight: valueWeight),
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

// BlockedUsersView remains unchanged
class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];

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
      final blocksData = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', myId);

      final List<dynamic> rawList = blocksData as List;
      final List<String> blockedIds =
      rawList.map((e) => e['blocked_id'].toString()).toList();

      if (blockedIds.isNotEmpty) {
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
    // ... (existing code: BlockedUsersView build implementation)
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.blockedUserManagement,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _blockedUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noBlockedUsers,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                final String nickname = user['nickname'] ?? l10n.noName;
                final String? profileUrl = user['profile_image_url'];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(profileUrl)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: (profileUrl == null || profileUrl.isEmpty)
                        ? const Icon(Icons.person, size: 20, color: Colors.grey)
                        : null,
                  ),
                  title: Text(nickname,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  trailing: OutlinedButton(
                    onPressed: () => _unblockUser(user['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(l10n.unblock),
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
