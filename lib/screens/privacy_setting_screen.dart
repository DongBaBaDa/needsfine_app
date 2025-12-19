import 'package:flutter/material.dart';

class PrivacySettingScreen extends StatefulWidget {
  const PrivacySettingScreen({super.key});

  @override
  State<PrivacySettingScreen> createState() => _PrivacySettingScreenState();
}

class _PrivacySettingScreenState extends State<PrivacySettingScreen> {
  bool _isPrivate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 공개 범위'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('전체 공개', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildProfilePreviewCard(),
          const SizedBox(height: 24),
          const Divider(),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            title: const Text('팔로워에게만 공개', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: const Text('나를 팔로우하는 사람만 내 활동을 확인할 수 있습니다.'),
            value: _isPrivate,
            onChanged: (bool value) {
              setState(() {
                _isPrivate = value;
              });
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildProfilePreviewCard() {
    // A simplified version of the profile card from the screenshot
    return AbsorbPointer(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const CircleAvatar(child: Text('김')),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('김캐치', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('팔로워 213 | 팔로잉 124', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(onPressed: null, child: const Text('+ 팔로우')),
                ],
              ),
              const SizedBox(height: 16),
              // Mock content
              Container(height: 40, color: Colors.grey[200], child: const Center(child: Text('리뷰 영역'))),
              const SizedBox(height: 8),
              Container(height: 60, color: Colors.grey[200], child: const Center(child: Text('컬렉션 영역'))),
            ],
          ),
        ),
      ),
    );
  }
}
