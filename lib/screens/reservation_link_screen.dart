import 'package:flutter/material.dart';

class ReservationLinkScreen extends StatefulWidget {
  const ReservationLinkScreen({super.key});

  @override
  State<ReservationLinkScreen> createState() => _ReservationLinkScreenState();
}

class _ReservationLinkScreenState extends State<ReservationLinkScreen> {
  bool _isLinked = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 연동하기'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            title: const Text('전화·링크 예약 앱에 연동하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            value: _isLinked,
            onChanged: (bool value) {
              setState(() {
                _isLinked = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '휴대폰 번호: 01051956372',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const Divider(height: 32),
          _buildSectionTitle('예약 연동이란?'),
          _buildInfoText('전화 또는 예약 링크로 한 예약을 앱에서 관리할 수 있게 하는 기능입니다. 예약에 사용한 휴대폰 번호로 방문예정일을 불러올 수 있어요!'),
          _buildInfoText('캐치테이블 가맹점 예약만 연동 가능하며, 연동하기 활성화 이전에 방문했던 전화 예약 내역은 불러올 수 없습니다.', icon: Icons.info_outline),
          _buildInfoText('전화 또는 예약 링크로 한 예약은 각 레스토랑의 운영 정책에 따라 앱에서 예약 취소 및 변경이 불가능할 수 있습니다.', icon: Icons.info_outline),
          const SizedBox(height: 24),
          _buildSectionTitle('예약 링크란?'),
          _buildInfoText('캐치테이블 가맹점을 예약할 수 있는 웹페이지 링크를 말합니다.'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoText(String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: Colors.orange, size: 18),
          if (icon != null) const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], height: 1.5))),
        ],
      ),
    );
  }
}
