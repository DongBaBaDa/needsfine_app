import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/data/korean_regions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // 지역 선택 관련 변수
  String? _selectedSido;
  String? _selectedSigungu;
  List<String> _sidoList = [];
  List<String> _sigunguList = [];

  // 상태 관리 변수
  bool? _isNicknameAvailable;
  bool _isCheckingNickname = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _sidoList = koreanRegions.keys.toList();

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

    // 활동 지역 초기 설정 (데이터 파싱 및 유효성 검사)
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

  @override
  void dispose() {
    _nicknameController.dispose();
    _introController.dispose();
    super.dispose();
  }

  // 닉네임 중복 확인 (금지어 로직 포함)
  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    // 1. 금지어 체크: '니즈파인' 포함 금지 (운영자 제외)
    // 운영자의 닉네임이나 특정 ID를 조건으로 걸 수 있습니다.
    if (nickname.contains('니즈파인') && nickname != '오재준') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("'니즈파인'은 운영자만 사용할 수 있습니다.")),
      );
      setState(() => _isNicknameAvailable = false);
      return;
    }

    if (nickname == widget.userProfile.nickname) {
      setState(() => _isNicknameAvailable = true);
      return;
    }

    setState(() => _isCheckingNickname = true);

    try {
      final res = await _supabase
          .from('profiles')
          .select('nickname')
          .eq('nickname', nickname)
          .maybeSingle();

      setState(() {
        _isNicknameAvailable = res == null;
      });
    } catch (e) {
      debugPrint('중복 체크 에러: $e');
    } finally {
      setState(() => _isCheckingNickname = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _updatedProfile.imageFile = File(pickedFile.path);
      });
    }
  }

  // 이미지 업로드 로직 (Supabase Storage)
  Future<String?> _uploadProfileImage() async {
    if (_updatedProfile.imageFile == null) return null;

    final userId = _supabase.auth.currentUser!.id;
    final file = _updatedProfile.imageFile!;
    final fileExt = file.path.split('.').last;
    final fileName = 'profile_$userId.${fileExt.toLowerCase()}';
    final filePath = '$userId/$fileName';

    try {
      await _supabase.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('이미지 업로드 에러: $e');
      return null;
    }
  }

  // 서버 저장 로직 (최종)
  Future<void> _saveAndPop() async {
    if (_nicknameController.text != widget.userProfile.nickname && _isNicknameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임 중복 확인이 필요합니다.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      String? newImageUrl;

      if (_updatedProfile.imageFile != null) {
        newImageUrl = await _uploadProfileImage();
      }

      // Supabase profiles 테이블 업데이트
      await _supabase.from('profiles').update({
        'nickname': _nicknameController.text.trim(),
        'introduction': _introController.text.trim(),
        'activity_zone': '$_selectedSido $_selectedSigungu',
        if (newImageUrl != null) 'profile_image_url': newImageUrl,
      }).eq('id', userId);

      if (mounted) {
        _updatedProfile.nickname = _nicknameController.text.trim();
        _updatedProfile.introduction = _introController.text.trim();
        _updatedProfile.activityZone = '$_selectedSido $_selectedSigungu';
        if (newImageUrl != null) _updatedProfile.profileImageUrl = newImageUrl;

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('정보가 서버에 저장되었습니다.')));
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
    // 운영자 왕관 표시 조건
    bool isOwner = _nicknameController.text == '오재준' || _nicknameController.text.contains('니즈파인');

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAndPop,
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeedsFinePurple,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("완료"),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 프로필 이미지 영역
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _updatedProfile.imageFile != null
                      ? FileImage(_updatedProfile.imageFile!) as ImageProvider
                      : (_updatedProfile.profileImageUrl.isNotEmpty
                      ? NetworkImage(_updatedProfile.profileImageUrl)
                      : null),
                  child: (_updatedProfile.imageFile == null && _updatedProfile.profileImageUrl.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(radius: 18, backgroundColor: Colors.grey[800], child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 닉네임 영역 (왕관 표시 포함)
          Row(
            children: [
              const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isOwner)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: '닉네임을 입력하세요',
                    border: const OutlineInputBorder(),
                    enabledBorder: _isNicknameAvailable == true
                        ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2))
                        : null,
                    errorText: _isNicknameAvailable == false ? '이미 사용 중인 닉네임입니다.' : null,
                    helperText: _isNicknameAvailable == true ? '사용 가능한 닉네임입니다.' : null,
                    helperStyle: const TextStyle(color: Colors.green),
                  ),
                  onChanged: (text) => setState(() => _isNicknameAvailable = null),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isCheckingNickname || _isNicknameAvailable == true) ? null : _checkNicknameDuplicate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNicknameAvailable == true ? Colors.green : Colors.grey[200],
                    foregroundColor: _isNicknameAvailable == true ? Colors.white : Colors.black,
                  ),
                  child: _isCheckingNickname
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isNicknameAvailable == true ? '확인됨' : '중복 확인'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 자기소개 영역
          const Text('자기소개', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _introController,
            maxLength: 35,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '자신을 알릴 수 있는 소개글을 작성해 주세요.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // 활동 지역 영역
          const Text('활동 지역', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSido,
            hint: const Text('시/도 선택'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _sidoList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSido = value;
                _selectedSigungu = null;
                _sigunguList = koreanRegions[value!] ?? [];
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSigungu,
            hint: const Text('시/군/구 선택'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _sigunguList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: _selectedSido == null ? null : (value) {
              setState(() => _selectedSigungu = value);
            },
          ),
        ],
      ),
    );
  }
}