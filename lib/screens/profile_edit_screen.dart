import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // 테마 import
import '../models/user_model.dart';
import 'sns_setting_screen.dart';
import 'taste_selection_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileEditScreen({super.key, required this.userProfile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _introController;
  late TextEditingController _activityZoneController;
  late UserProfile _updatedProfile;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _updatedProfile = UserProfile(
      nickname: widget.userProfile.nickname,
      introduction: widget.userProfile.introduction,
      activityZone: widget.userProfile.activityZone,
      profileImageUrl: widget.userProfile.profileImageUrl,
      imageFile: widget.userProfile.imageFile,
      reliability: widget.userProfile.reliability,
      followerCount: widget.userProfile.followerCount,
      followingCount: widget.userProfile.followingCount,
      birthDate: widget.userProfile.birthDate,
    );

    _nicknameController = TextEditingController(text: _updatedProfile.nickname);
    _introController = TextEditingController(text: _updatedProfile.introduction);
    _activityZoneController = TextEditingController(text: _updatedProfile.activityZone);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _introController.dispose();
    _activityZoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _updatedProfile.imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveAndPop() {
    _updatedProfile.nickname = _nicknameController.text;
    _updatedProfile.introduction = _introController.text;
    _updatedProfile.activityZone = _activityZoneController.text;
    Navigator.pop(context, _updatedProfile);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _updatedProfile.birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: kNeedsFinePurple)), child: child!);
      },
    );
    if (picked != null && picked != _updatedProfile.birthDate) {
      setState(() {
        _updatedProfile.birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          // [수정] Primary Button 스타일 적용
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _saveAndPop,
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeedsFinePurple,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text("완료"),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _updatedProfile.imageFile != null
                            ? FileImage(_updatedProfile.imageFile!) as ImageProvider
                            : (_updatedProfile.profileImageUrl.isNotEmpty
                                ? NetworkImage(_updatedProfile.profileImageUrl)
                                : const AssetImage('assets/images/default_profile.png')
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(onTap: _pickImage, child: CircleAvatar(radius: 18, backgroundColor: Colors.grey[800], child: const Icon(Icons.camera_alt, color: Colors.white, size: 20))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(label: '닉네임', controller: _nicknameController),
                _buildTextField(label: '자기 소개', controller: _introController, hint: '자신을 알릴 수 있는 소개글을 작성해 주세요.', maxLength: 35, maxLines: 3),
                _buildTextField(label: '활동 지역', controller: _activityZoneController, hint: '활동 지역을 자유롭게 입력해주세요.', prefixIcon: Icons.location_on_outlined),
                const Divider(height: 40),
                _buildListTile(title: 'SNS 설정하기', value: '미설정', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SnsSettingScreen()))),
                _buildListTile(title: '내 취향 선택하기', value: '미설정', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasteSelectionScreen()))),
                _buildListTile(
                  title: '생일/기념일 등록하기', 
                  value: _updatedProfile.birthDate != null ? DateFormat('yyyy-MM-dd').format(_updatedProfile.birthDate!) : '0 건', 
                  onTap: () => _selectDate(context)
                ),
              ],
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
            decoration: InputDecoration(hintText: hint, prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null, border: const OutlineInputBorder()),
            onChanged: (text) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(value, style: const TextStyle(color: Colors.grey)), const Icon(Icons.chevron_right, color: Colors.grey)]),
      onTap: onTap,
    );
  }
}
