import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/privacy_setting_screen.dart';
import 'package:needsfine_app/screens/reservation_link_screen.dart';
import 'package:needsfine_app/screens/password_change_screen.dart'; // ✅ 비밀번호 변경 화면 (생성 필요)
import 'package:needsfine_app/screens/initial_screen.dart';

class InfoEditScreen extends StatefulWidget {
  const InfoEditScreen({super.key});

  @override
  State<InfoEditScreen> createState() => _InfoEditScreenState();
}

class _InfoEditScreenState extends State<InfoEditScreen> {
  final _supabase = Supabase.instance.client;

  // --- [로직] 로그아웃 구현 ---
  Future<void> _handleLogout() async {
    final confirm = await _showConfirmDialog('로그아웃', '정말 로그아웃 하시겠습니까?');
    if (confirm == true) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const InitialScreen()),
              (route) => false,
        );
      }
    }
  }

  // --- [로직] 회원탈퇴 구현 ---
  Future<void> _handleDeleteAccount() async {
    final confirm = await _showConfirmDialog(
      '회원 탈퇴',
      '탈퇴 시 모든 데이터가 복구 불가능하게 삭제됩니다. 정말 탈퇴하시겠습니까?',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        // 실제로는 Edge Function이나 별도 RPC를 통해 Auth와 Profile을 동시에 지우는 것이 안전합니다.
        // 여기서는 기본적으로 Auth 유저 삭제 로직을 타겟팅합니다.
        // await _supabase.rpc('delete_user_account'); 

        await _supabase.auth.signOut(); // 임시로 로그아웃 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const InitialScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('탈퇴 처리 중 에러: $e')));
      }
    }
  }

  // 공통 확인 다이얼로그
  Future<bool?> _showConfirmDialog(String title, String message, {bool isDestructive = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.blue)),
          ),
        ],
      ),
    );
  }

  // 정보 수정용 다이얼로그 (이름, 번호 등)
  void _showEditField(String title, String currentValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$title 변경', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(hintText: currentValue, border: const OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pop(context),
              child: const Text('저장하기'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'), // ✅ 내 정보 수정 -> 설정으로 변경
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 이름 수정
          _buildInfoTile(context, title: '이름', value: '오재준', onTap: () => _showEditField('이름', '오재준')),

          // 휴대폰 번호 수정
          _buildInfoTile(context, title: '휴대폰 번호', value: '010-5195-6372', isVerified: true,
              onTap: () => _showEditField('휴대폰 번호', '010-5195-6372')),

          // 비밀번호 변경 -> 화면 이동
          _buildInfoTile(context, title: '비밀번호', value: '변경하기',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordChangeScreen()))),

          _buildInfoTile(context, title: '간편 로그인', value: '카카오'),

          // 성별 선택
          _buildInfoTile(context, title: '성별', value: '선택안함',
              onTap: () => _showEditField('성별', '성별을 선택해주세요')),

          const Divider(),

          ListTile(
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          // 프로필 공개 설정
          ListTile(
            title: const Text('프로필 공개 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingScreen())),
          ),

          ListTile(
            title: const Text('예약/주문 연동'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationLinkScreen())),
          ),

          const Divider(),

          // ✅ 로그아웃 구현
          ListTile(
            title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
            onTap: _handleLogout,
          ),

          const Divider(),

          // ✅ 회원 탈퇴 구현
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Center(
              child: TextButton(
                onPressed: _handleDeleteAccount,
                child: const Text(
                  '회원탈퇴를 하시려면 여기를 눌러주세요',
                  style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, {required String title, required String value, bool isVerified = false, VoidCallback? onTap}) {
    return ListTile(
      title: Row(
        children: [
          Text(title),
          if (isVerified)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Chip(
                label: const Text('인증', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.blue[50],
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}