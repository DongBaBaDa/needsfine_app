import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // kNeedsFinePurple 사용
import 'package:needsfine_app/l10n/app_localizations.dart';
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

  // ✅ 더 밝고 화사한 니즈파인 대표 컬러 적용 (0xFFC87CFF)
  // 기존 0xFF8A2BE2(BlueViolet)보다 밝은 톤
  final Color _primaryColor = const Color(0xFFC87CFF);

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

    _introController = TextEditingController(
        text: (_updatedProfile.introduction == '자신을 알릴 수 있는 소개글을 작성해 주세요.' ||
            _updatedProfile.introduction == '자기소개를 입력해주세요.' ||
            _updatedProfile.introduction.isEmpty)
            ? ""
            : _updatedProfile.introduction
    );

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nicknameUnavailable)));
      setState(() => _isNicknameAvailable = false);
      return;
    }

    if (nickname == widget.userProfile.nickname) {
      setState(() => _isNicknameAvailable = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nicknameCurrent)));
      return;
    }

    setState(() => _isCheckingNickname = true);

    try {
      final res = await _supabase.from('profiles').select('nickname').eq('nickname', nickname).maybeSingle();
      setState(() => _isNicknameAvailable = res == null);

      if (mounted) {
        if (_isNicknameAvailable == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nicknameAvailable)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nicknameTaken)));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.processFailed(e.toString()))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showCrown = _isAdminInDB || _nicknameController.text.contains('니즈파인');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.editProfileTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveAndPop,
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor, // 버튼 색상 밝게
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              child: _isSaving
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 2))
                  : Text(l10n.saveAction),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 색다른 느낌을 주기 위해 상단 프로필 영역에 은은한 배경 추가
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _primaryColor.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4), // 흰색 테두리 강조
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ], // 그림자로 입체감
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: _updatedProfile.imageFile != null
                            ? FileImage(_updatedProfile.imageFile!) as ImageProvider
                            : (_updatedProfile.profileImageUrl.isNotEmpty ? NetworkImage(_updatedProfile.profileImageUrl) : null),
                        child: (_updatedProfile.imageFile == null && _updatedProfile.profileImageUrl.isEmpty)
                            ? const Icon(Icons.person, size: 54, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor, // 밝은 보라 포인트
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. 닉네임
                  _buildSectionLabel(l10n.nicknameLabel, icon: showCrown ? Icons.workspace_premium : null, iconColor: Colors.amber),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nicknameController,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      hintText: l10n.nicknameLabel,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      // 포커스 시 밝은 보라색
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: TextButton(
                          onPressed: (_isCheckingNickname || _isNicknameAvailable == true) ? null : _checkNicknameDuplicate,
                          style: TextButton.styleFrom(
                            foregroundColor: _isNicknameAvailable == true ? Colors.green : Colors.grey[600],
                            backgroundColor: _isNicknameAvailable == true ? Colors.green.withOpacity(0.1) : Colors.grey[200],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(60, 36),
                          ),
                          child: _isCheckingNickname
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                            _isNicknameAvailable == true ? l10n.checked : l10n.checkDuplicate,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    onChanged: (text) => setState(() => _isNicknameAvailable = null),
                  ),
                  if (_isNicknameAvailable == false)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(l10n.nicknameUnavailable, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),

                  const SizedBox(height: 28),

                  // 3. 활동 지역
                  _buildSectionLabel(l10n.activityZoneLabel),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedSido,
                          hint: l10n.selectSido,
                          items: _sidoList,
                          onChanged: (value) {
                            setState(() {
                              _selectedSido = value;
                              _selectedSigungu = null;
                              _sigunguList = koreanRegions[value!] ?? [];
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedSigungu,
                          hint: l10n.selectSigungu,
                          items: _sigunguList,
                          onChanged: _selectedSido == null ? null : (value) => setState(() => _selectedSigungu = value),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 4. 소개
                  _buildSectionLabel(l10n.introLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _introController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    maxLength: 100,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      hintText: l10n.introHint,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
                      counterText: "", // Hide default counter
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ValueListenableBuilder(
                      valueListenable: _introController,
                      builder: (context, value, child) {
                        return Text(
                          "${value.text.length}/100",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, {IconData? icon, Color? iconColor}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        if (icon != null) ...[
          const SizedBox(width: 4),
          Icon(icon, color: iconColor, size: 16),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}