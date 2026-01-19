import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // kNeedsFinePurple 사용
import 'package:needsfine_app/data/korean_regions.dart'; // 지역 데이터
import '../models/user_model.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileEditScreen({super.key, required this.userProfile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _nicknameController;
  late TextEditingController _introController;
  late UserProfile _updatedProfile;

  String? _selectedSido;
  String? _selectedSigungu;
  List<String> _sidoList = [];
  List<String> _sigunguList = [];

  bool? _isNicknameAvailable;
  bool _isCheckingNickname = false;
  bool _isSaving = false;
  bool _isAdminInDB = false;

  final ImagePicker _picker = ImagePicker();

  // 디자인용 상수
  final Color _inputFillColor = const Color(0xFFF5F5F5);
  final Color _primaryColor = const Color(0xFF8A2BE2); // kNeedsFinePurple 대응

  @override
  void initState() {
    super.initState();
    _sidoList = koreanRegions.keys.toList();
    _fetchAdminStatus();

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

    // 힌트 텍스트 처리 로직 유지
    _introController = TextEditingController(
        text: (_updatedProfile.introduction == '자신을 알릴 수 있는 소개글을 작성해 주세요.' ||
            _updatedProfile.introduction == '자기소개를 입력해주세요.' ||
            _updatedProfile.introduction.isEmpty)
            ? ""
            : _updatedProfile.introduction
    );

    // 지역 초기화 로직 유지
    if (_updatedProfile.activityZone.isNotEmpty) {
      final zones = _updatedProfile.activityZone.split(' ');
      if (zones.length >= 2) {
        final targetSido = zones[0];
        final targetSigungu = zones[1];

        if (_sidoList.contains(targetSido)) {
          _selectedSido = targetSido;
          _sigunguList = koreanRegions[_selectedSido!] ?? [];
          if (_sigunguList.contains(targetSigungu)) {
            _selectedSigungu = targetSigungu;
          }
        }
      }
    }
  }

  Future<void> _fetchAdminStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = await _supabase.from('profiles').select('is_admin').eq('id', userId).maybeSingle();
    if (data != null && mounted) {
      setState(() => _isAdminInDB = data['is_admin'] ?? false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    if (nickname.contains('니즈파인') && !_isAdminInDB) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("해당 닉네임은 사용할 수 없습니다.")));
      setState(() => _isNicknameAvailable = false);
      return;
    }

    if (nickname == widget.userProfile.nickname) {
      setState(() => _isNicknameAvailable = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("현재 사용 중인 닉네임입니다.")));
      return;
    }

    setState(() => _isCheckingNickname = true);

    try {
      final res = await _supabase.from('profiles').select('nickname').eq('nickname', nickname).maybeSingle();
      setState(() => _isNicknameAvailable = res == null);

      if (mounted) {
        if (_isNicknameAvailable == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사용 가능한 닉네임입니다.")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 존재하는 닉네임입니다.")));
        }
      }
    } catch (e) {
      debugPrint('중복 체크 에러: $e');
    } finally {
      setState(() => _isCheckingNickname = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _updatedProfile.imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_updatedProfile.imageFile == null) return null;
    final userId = _supabase.auth.currentUser!.id;
    final file = _updatedProfile.imageFile!;
    final fileExt = file.path.split('.').last;
    final fileName = 'profile_$userId.${fileExt.toLowerCase()}';
    final filePath = '$userId/$fileName';

    try {
      await _supabase.storage.from('avatars').upload(filePath, file, fileOptions: const FileOptions(upsert: true));
      return _supabase.storage.from('avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('이미지 업로드 에러: $e');
      return null;
    }
  }

  Future<void> _saveAndPop() async {
    if (_nicknameController.text != widget.userProfile.nickname && _isNicknameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임 중복 확인이 필요합니다.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final email = _supabase.auth.currentUser!.email;
      String? newImageUrl;

      if (_updatedProfile.imageFile != null) {
        newImageUrl = await _uploadProfileImage();
      }

      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'nickname': _nicknameController.text.trim(),
        'introduction': _introController.text.trim(),
        'activity_zone': '$_selectedSido $_selectedSigungu',
        if (newImageUrl != null) 'profile_image_url': newImageUrl,
      });

      if (mounted) {
        _updatedProfile.nickname = _nicknameController.text.trim();
        _updatedProfile.introduction = _introController.text.trim();
        _updatedProfile.activityZone = '$_selectedSido $_selectedSigungu';
        if (newImageUrl != null) _updatedProfile.profileImageUrl = newImageUrl;

        Navigator.pop(context, _updatedProfile);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showCrown = _isAdminInDB || _nicknameController.text.contains('니즈파인');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필 수정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAndPop,
            child: _isSaving
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 2))
                : Text("완료", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 이미지
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _updatedProfile.imageFile != null
                        ? FileImage(_updatedProfile.imageFile!) as ImageProvider
                        : (_updatedProfile.profileImageUrl.isNotEmpty ? NetworkImage(_updatedProfile.profileImageUrl) : null),
                    child: (_updatedProfile.imageFile == null && _updatedProfile.profileImageUrl.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. 닉네임 입력 (Filled Style + 내부 중복확인 버튼)
            Row(
              children: [
                const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (showCrown)
                  const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.workspace_premium, color: Colors.amber, size: 18)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: _inputFillColor,
                hintText: '닉네임을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                // 중복 확인 버튼을 입력창 내부로 이동
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextButton(
                    onPressed: (_isCheckingNickname || _isNicknameAvailable == true) ? null : _checkNicknameDuplicate,
                    style: TextButton.styleFrom(
                      foregroundColor: _isNicknameAvailable == true ? Colors.green : Colors.grey[600],
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: _isCheckingNickname
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                      _isNicknameAvailable == true ? '확인됨' : '중복확인',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              onChanged: (text) => setState(() => _isNicknameAvailable = null),
            ),
            if (_isNicknameAvailable == false)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text("해당 닉네임은 사용할 수 없습니다.", style: TextStyle(color: Colors.red, fontSize: 12)),
              ),

            const SizedBox(height: 24),

            // 3. 자기소개
            const Text('소개', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _introController,
              maxLength: 35,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: _inputFillColor,
                hintText: '자신을 알릴 수 있는 소개글을 작성해 주세요.',
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
              ),
            ),

            const SizedBox(height: 24),

            // 4. 활동 지역 (드롭다운 디자인 일치화)
            const Text('주 활동 지역', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: _inputFillColor, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSido,
                        hint: Text('시/도', style: TextStyle(color: Colors.grey[400])),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                        isExpanded: true,
                        items: _sidoList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSido = value;
                            _selectedSigungu = null;
                            _sigunguList = koreanRegions[value!] ?? [];
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: _inputFillColor, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSigungu,
                        hint: Text('시/군/구', style: TextStyle(color: Colors.grey[400])),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                        isExpanded: true,
                        items: _sigunguList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: _selectedSido == null ? null : (value) => setState(() => _selectedSigungu = value),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}