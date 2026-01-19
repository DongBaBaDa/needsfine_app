import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/email_login_screen.dart';
import 'package:needsfine_app/screens/password_change_screen.dart';
import 'package:needsfine_app/screens/terms_screen.dart'; // ✅ 약관 화면 임포트

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

      try {
        final data = await _supabase
            .from('profiles')
            .select('phone, gender')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          _phone = data['phone'] ?? '';
          _gender = data['gender'] ?? '미설정';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("회원 탈퇴"),
        content: const Text("정말로 탈퇴하시겠습니까? 계정 정보와 활동 내역이 모두 삭제됩니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("탈퇴", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("회원 탈퇴 처리가 완료되었습니다.")));
      _logout();
    }
  }

  void _showPhoneAuthDialog() {
    final phoneController = TextEditingController(text: _phone);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("휴대폰 번호 인증"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "휴대폰 번호 입력 (- 없이)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text("인증번호가 발송됩니다. (모의 기능)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                final newPhone = phoneController.text.trim();
                if (newPhone.isNotEmpty) {
                  try {
                    await _supabase.from('profiles').update({'phone': newPhone}).eq('id', _supabase.auth.currentUser!.id);
                    setState(() => _phone = newPhone);
                    if(mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("인증 완료되었습니다.")));
                  } catch(e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 실패")));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A2BE2), foregroundColor: Colors.white),
              child: const Text("인증"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
          _buildSectionHeader("계정 정보"),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.phone_iphone,
              label: "휴대폰 번호",
              value: _phone.isEmpty ? "인증 필요" : _phone,
              onTap: _showPhoneAuthDialog,
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.email_outlined,
              label: "이메일",
              value: _email,
              showArrow: false,
            ),
            _buildDivider(),
            // ✅ [성별 표시]
            _buildSettingsItem(
              icon: Icons.wc,
              label: "성별",
              value: _gender, // DB에서 가져온 값 표시
              showArrow: false,
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader("보안 및 알림"),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.lock_outline,
              label: "비밀번호 변경",
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
                  const Text("알림 설정", style: TextStyle(fontSize: 16, color: Colors.black87)),
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
          // ✅ [이용약관 버튼 추가]
          _buildSectionHeader("정보"),
          _buildSectionContainer([
            _buildSettingsItem(
              icon: Icons.description_outlined,
              label: "이용약관",
              value: "",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen())),
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
              child: const Text("로그아웃", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 20),
          const Center(child: Text("현재 버전 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 10),

          // ✅ [회원탈퇴: 눈에 안 띄게 회색 처리]
          Center(
            child: TextButton(
              onPressed: _deleteAccount,
              child: Text(
                "회원 탈퇴하기",
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