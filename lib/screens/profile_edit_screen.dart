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
  late UserProfile _updatedProfile;

  // 지역 선택 관련 변수
  String? _selectedSido;
  String? _selectedSigungu;
  List<String> _sidoList = [];
  List<String> _sigunguList = [];

  // 상태 관리 변수
  bool? _isNicknameAvailable;
  bool _isCheckingNickname = false;
  bool _isSaving = false; // 서버 저장 로딩

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

    // [해결] Screenshot_20251230_204308.jpg의 '활동' 값 오류 방어 코드
    if (_updatedProfile.activityZone.isNotEmpty) {
      final zones = _updatedProfile.activityZone.split(' ');
      if (zones.length >= 2) {
        final targetSido = zones[0];
        final targetSigungu = zones[1];

        // "활동"처럼 리스트에 없는 값이 들어오면 드롭다운 오류가 나므로 contains 체크 필수
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
    super.dispose();
  }

  // 닉네임 중복 확인
  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;
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

  // 이미지 선택
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _updatedProfile.imageFile = File(pickedFile.path);
      });
    }
  }

  // [서버 저장] 이미지 업로드 로직
  Future<String?> _uploadProfileImage() async {
    if (_updatedProfile.imageFile == null) return null;

    final userId = _supabase.auth.currentUser!.id;
    final file = _updatedProfile.imageFile!;
    final fileExt = file.path.split('.').last;
    final fileName = 'profile_$userId.${fileExt.toLowerCase()}';
    final filePath = '$userId/$fileName';

    try {
      // 업로드 실행
      await _supabase.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // 업로드된 이미지의 Public URL 획득
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('이미지 업로드 에러: $e');
      return null;
    }
  }

  // [서버 저장] 최종 완료 버튼 로직
  Future<void> _saveAndPop() async {
    if (_nicknameController.text != widget.userProfile.nickname && _isNicknameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임 중복 확인이 필요합니다.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      String? newImageUrl;

      // 1. 이미지가 바뀌었다면 서버 스토리지에 업로드
      if (_updatedProfile.imageFile != null) {
        newImageUrl = await _uploadProfileImage();
      }

      // 2. DB 정보 업데이트
      await _supabase.from('profiles').update({
        'nickname': _nicknameController.text.trim(),
        'activity_zone': '$_selectedSido $_selectedSigungu',
        if (newImageUrl != null) 'profile_image_url': newImageUrl,
      }).eq('id', userId);

      if (mounted) {
        _updatedProfile.nickname = _nicknameController.text.trim();
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
          Center(
            child: Stack(
              children: [
                // [해결] 에셋 파일 부재 에러 방지를 위해 기본 아이콘 사용
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
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  onChanged: (text) {
                    setState(() {
                      _isNicknameAvailable = null;
                    });
                  },
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
                    elevation: 0,
                  ),
                  child: _isCheckingNickname
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isNicknameAvailable == true ? '확인됨' : '중복 확인'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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