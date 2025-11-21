import 'package:flutter/material.dart';
import 'dart:math'; // For random nickname generation
import '../models/user_model.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const ProfileEditScreen({super.key, required this.currentProfile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _verificationCodeController;
  late TextEditingController _emailController;

  String? _selectedGender;
  late String _selectedIconPath;
  late String _selectedTitle;

  final List<String> _genders = ['남성', '여성', '기타'];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentProfile.nickname);
    _bioController = TextEditingController(text: widget.currentProfile.introduction);
    // Fix: Handle potential null value from profileImagePath
    _selectedIconPath = widget.currentProfile.profileImagePath ?? '';
    _selectedTitle = widget.currentProfile.title;

    // New controllers
    // TODO: Load saved data from profile if it exists
    _ageController = TextEditingController();
    _phoneController = TextEditingController();
    _verificationCodeController = TextEditingController();
    _emailController = TextEditingController();
    _selectedGender = null; // Or load from profile if available
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    // TODO: The UserProfile model needs to be updated to support all new fields.
    // For now, only updated fields that already exist in the model will be saved.
    final updatedProfile = UserProfile(
      nickname: _nicknameController.text.isNotEmpty
          ? _nicknameController.text
          : 'needsfineuser${Random().nextInt(10000)}',
      introduction: _bioController.text,
      title: _selectedTitle.isNotEmpty ? _selectedTitle : "현재 개발중",
      profileImagePath: _selectedIconPath,
      // These are not editable in the new UI, just pass them through
      level: widget.currentProfile.level,
      currentExp: widget.currentProfile.currentExp,
      maxExp: widget.currentProfile.maxExp,
      influence: widget.currentProfile.influence,
      points: widget.currentProfile.points,
      // New fields like age, gender, phone etc. need to be added to UserProfile model
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 수정되었습니다.')),
    );

    Navigator.pop(context, updatedProfile);
  }

  // TODO: Navigate to icon selection screen
  void _selectIcon() {
    print("Navigate to icon selection screen");
    // This will be implemented in the next step.
    // For now, let's cycle through some placeholder images for testing.
    final List<String> placeholderImages = [
        'assets/images/painy.png',
        // Add other asset paths here to test
    ];
    // A quick check to avoid errors if the list is empty or the current path is not in the list
    if(placeholderImages.isNotEmpty) {
        final currentIndex = placeholderImages.indexOf(_selectedIconPath);
        final nextIndex = (currentIndex + 1) % placeholderImages.length;
        setState(() {
          _selectedIconPath = placeholderImages[nextIndex];
        });
    }
  }

  // TODO: Navigate to title selection screen
  void _selectTitle() {
    print("Navigate to title selection screen");
    // This will be implemented later.
     setState(() {
      _selectedTitle = "칭호 테스트 중";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("프로필 편집"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAndPop,
            child: const Text("적용", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _selectIcon,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _selectedIconPath.isNotEmpty
                      ? AssetImage(_selectedIconPath)
                      : null,
                  child: _selectedIconPath.isEmpty
                      ? Icon(Icons.add_a_photo, size: 80, color: Colors.grey[400])
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("칭호", style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedTitle.isNotEmpty ? _selectedTitle : "현재 개발중"),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithButton(
              context,
              controller: _nicknameController,
              labelText: "닉네임",
              buttonText: "중복확인",
              onButtonPressed: () {
                // TODO: Implement nickname duplication check
              },
            ),
            const SizedBox(height: 16),
            _buildBioField(context, controller: _bioController),
            const SizedBox(height: 16),
            _buildGenderField(context),
            const SizedBox(height: 16),
            _buildTextField(context, controller: _ageController, labelText: "나이", keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextFieldWithButton(
              context,
              controller: _phoneController,
              labelText: "전화번호",
              hintText: "결제 등 원활한 기능 이용을 위해 필요합니다.",
              buttonText: "인증요청",
              onButtonPressed: () {
                // TODO: Implement phone verification request
              },
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithButton(
              context,
              controller: _verificationCodeController,
              labelText: "전화번호 인증",
              buttonText: "확인",
              onButtonPressed: () {
                // TODO: Implement verification code check
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(context, controller: _emailController, labelText: "이메일 주소", keyboardType: TextInputType.emailAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context,
      {required TextEditingController controller,
      required String labelText,
      bool readOnly = false,
      TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        )
      ],
    );
  }

  Widget _buildTextFieldWithButton(BuildContext context,
      {required TextEditingController controller,
      required String labelText,
      required String buttonText,
      required VoidCallback onButtonPressed,
      String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: Theme.of(context).textTheme.labelLarge),
        if (hintText != null) ...[
            const SizedBox(height: 4),
            Text(hintText, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText))
          ],
        )
      ],
    );
  }

  Widget _buildBioField(BuildContext context, {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("자기소개", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: "최대 50자",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("성별 (선택사항)", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          hint: const Text("성별 선택"),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: _genders.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ],
    );
  }
}
