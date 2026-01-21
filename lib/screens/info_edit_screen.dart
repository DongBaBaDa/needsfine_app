import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/email_login_screen.dart';
import 'package:needsfine_app/screens/password_change_screen.dart';
import 'package:needsfine_app/screens/terms_screen.dart';
import 'package:needsfine_app/screens/language_settings_screen.dart'; // ✅ 언어 설정 화면 임포트
import 'package:needsfine_app/l10n/app_localizations.dart'; // ✅ 다국어 패키지

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

      // 1. user_metadata에서 성별 확인 (회원가입 시 보통 여기에 저장됨)
      final metaGender = user.userMetadata?['gender'];
      if (metaGender != null) {
        _gender = metaGender.toString();
      }

      // 2. profiles 테이블에서도 확인 (DB 우선)
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccount, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("회원 탈퇴 처리가 완료되었습니다.")));
      _logout();
    }
  }

  // ✅ 휴대폰 번호 인증 (개발 중 팝업으로 변경)
  void _showPhoneAuthDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(l10n.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_circle_outlined, size: 48, color: Color(0xFF8A2BE2)), // NeedsFine Color
              const SizedBox(height: 16),
              Text(l10n.developingMessage, style: const TextStyle(fontSize: 16)), // "현재 개발 중인 기능입니다."
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.confirm, style: const TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
              // 성별 정보 표시 (번역이 필요하면 조건문 추가 가능)
              value: _gender == '미설정' ? l10n.unspecified : _gender,
              showArrow: false,
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(l10n.general),
          _buildSectionContainer([
            // ✅ [수정] 아이콘 변경 (Icons.translate)
            _buildSettingsItem(
              icon: Icons.translate, // 구글 번역기 느낌의 아이콘
              label: l10n.languageSettings,
              value: "",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen())),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(l10n.securityAndNotifications),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.lock_outline,
              label: l10n.changePassword,
              value: "",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PasswordChangeScreen())),
            ),
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
                    value: _isNotificationOn,
                    activeColor: const Color(0xFF8A2BE2),
                    onChanged: (val) => setState(() => _isNotificationOn = val),
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen())),
            ),
            _buildDivider(),
            // 1:1 문의 추가 (선택사항)
            _buildSettingsItem(
              icon: Icons.support_agent,
              label: l10n.inquiry,
              value: "",
              onTap: () {
                // 문의 화면 이동 로직
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(l10n.logout, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 20),
          Center(child: Text("${l10n.currentVersion} 1.0.0", style: const TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 10),

          Center(
            child: TextButton(
              onPressed: _deleteAccount,
              child: Text(
                l10n.deleteAccount,
                style: TextStyle(color: Colors.grey[400], fontSize: 12, decoration: TextDecoration.underline),
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
      child: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String label, required String value, VoidCallback? onTap, bool showArrow = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(width: 16),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 15, color: Colors.grey), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            if (showArrow) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey)],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 50, endIndent: 0, color: Color(0xFFEEEEEE));
}