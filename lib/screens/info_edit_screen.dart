import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/privacy_setting_screen.dart';
import 'package:needsfine_app/screens/reservation_link_screen.dart';

class InfoEditScreen extends StatelessWidget {
  const InfoEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 수정'),
      ),
      body: ListView(
        children: [
          _buildInfoTile(context, title: '이름', value: '오재준'),
          _buildInfoTile(context, title: '휴대폰 번호', value: '010-5195-6372', isVerified: true),
          _buildInfoTile(context, title: '비밀번호', value: '미설정'),
          _buildInfoTile(context, title: '간편 로그인', value: '카카오'),
          _buildInfoTile(context, title: '성별', value: '선택안함'),
          const Divider(),
          ListTile(
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          // [추가] 프로필 공개 범위 설정 메뉴
          ListTile(
            title: const Text('프로필 공개 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingScreen())),
          ),
          // [추가] 예약/주문 연동 메뉴
          ListTile(
            title: const Text('예약/주문 연동'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationLinkScreen())),
          ),
          const Divider(),
          ListTile(
            title: const Text('로그아웃'),
            onTap: () {},
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Center(
              child: TextButton(
                onPressed: () {},
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

  Widget _buildInfoTile(BuildContext context, {required String title, required String value, bool isVerified = false}) {
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
      onTap: () {},
    );
  }
}
