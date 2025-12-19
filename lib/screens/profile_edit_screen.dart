import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nicknameController = TextEditingController(text: '발랄한 맛사냥꾼_53515');
  final _introController = TextEditingController();
  final _activityZoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 프로필 사진
                Center(
                  child: Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Placeholder
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 닉네임
                _buildTextField(label: '닉네임', controller: _nicknameController),
                
                // 자기소개
                _buildTextField(label: '자기 소개', controller: _introController, hint: '자신을 알릴 수 있는 소개글을 작성해 주세요.', maxLength: 35, maxLines: 3),

                // 활동 지역
                _buildTextField(label: '활동 지역', controller: _activityZoneController, hint: '활동 지역을 자유롭게 입력해주세요.', prefixIcon: Icons.location_on_outlined),
                
                const Divider(height: 40),

                // 리스트 메뉴
                _buildListTile(title: 'SNS 설정하기', value: '입력된 SNS정보가 없습니다.', onTap: () {}),
                _buildListTile(title: '내 취향 선택하기', value: '미설정', onTap: () {}),
                _buildListTile(title: '생일/기념일 등록하기', value: '0 건', onTap: () {}),
              ],
            ),
          ),
          // 저장 버튼
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, String? hint, int? maxLength, int maxLines = 1, IconData? prefixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              counterText: maxLength != null ? '${controller.text.length}/$maxLength' : '',
            ),
            onChanged: (text) => setState(() {}), // To update the character counter
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
