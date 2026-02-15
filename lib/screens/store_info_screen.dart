// lib/screens/store_info_screen.dart
// 매장 정보 페이지 (나무위키 스타일) — v2 피드백 반영
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:needsfine_app/screens/admin/store_edit_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreInfoScreen extends StatefulWidget {
  final String storeName;
  final String storeAddress;
  final double lat;
  final double lng;

  const StoreInfoScreen({
    super.key,
    required this.storeName,
    required this.storeAddress,
    required this.lat,
    required this.lng,
  });

  @override
  State<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  Map<String, dynamic>? _storeData;
  bool _isLoading = true;
  bool _isOfficial = false;
  bool _isOwner = false;
  bool _isSuperAdmin = false;
  List<Map<String, dynamic>> _editHistory = [];
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    setState(() => _isLoading = true);

    final userId = _supabase.auth.currentUser?.id;
    final email = _supabase.auth.currentUser?.email ?? '';
    _isSuperAdmin = email.toLowerCase() == 'ineedsfine@gmail.com';

    try {
      final storeResponse = await _supabase
          .from('stores')
          .select()
          .eq('name', widget.storeName)
          .maybeSingle();

      if (storeResponse != null) {
        _storeData = storeResponse;
        _isOfficial = storeResponse['is_official'] == true;

        // 조회수 증가
        await _supabase
            .from('stores')
            .update({'view_count': (storeResponse['view_count'] ?? 0) + 1})
            .eq('id', storeResponse['id']);

        // 사장 권한 확인
        if (userId != null) {
          final ownerCheck = await _supabase
              .from('store_owners')
              .select('id')
              .eq('store_id', storeResponse['id'])
              .eq('user_id', userId)
              .maybeSingle();
          _isOwner = ownerCheck != null;
        }

        // 편집 이력
        final edits = await _supabase
            .from('store_edits')
            .select('*, profiles:user_id(nickname)')
            .eq('store_id', storeResponse['id'])
            .order('created_at', ascending: false)
            .limit(20);
        _editHistory = List<Map<String, dynamic>>.from(edits);
      }
    } catch (e) {
      debugPrint("매장 정보 로드 실패: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ✅ 매장 정보 등록 (유저용 — 나무위키 스타일)
  Future<void> _registerStore() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase.from('stores').insert({
        'name': widget.storeName,
        'address': widget.storeAddress,
        'lat': widget.lat,
        'lng': widget.lng,
        'is_official': false,
        'registered_by': userId,
      }).select().single();

      setState(() {
        _storeData = response;
        _isOfficial = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('매장 정보가 등록되었습니다 ✅')),
        );
      }
    } catch (e) {
      debugPrint("매장 등록 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('매장 등록에 실패했습니다.')),
        );
      }
    }
  }

  // ✅ 운영자에게 오피셜 등록 요청
  Future<void> _requestOfficialRegistration() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('오피셜 매장 등록 요청'),
        content: Text(
          '\'${widget.storeName}\'을(를) 오피셜 매장으로 등록 요청하시겠습니까?\n\n운영자가 확인 후 승인합니다.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D3A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('요청하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // store_requests 테이블 또는 feedback 테이블에 저장
      final requestContent = '[오피셜 매장 등록 요청] ${widget.storeName}\n주소: ${widget.storeAddress}\n좌표: (${widget.lat}, ${widget.lng})';
      await _supabase.from('feedback').insert({
        'user_id': userId,
        'content': requestContent,
        'message': requestContent,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('운영자에게 등록 요청을 보냈습니다. ✅')),
        );
      }
    } catch (e) {
      debugPrint("요청 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요청 전송에 실패했습니다.')),
        );
      }
    }
  }

  // ✅ 오피셜 등록 (관리자 전용)
  Future<void> _registerAsOfficial() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || !_isSuperAdmin) return;

    try {
      final response = await _supabase.from('stores').insert({
        'name': widget.storeName,
        'address': widget.storeAddress,
        'lat': widget.lat,
        'lng': widget.lng,
        'is_official': true,
        'registered_by': userId,
      }).select().single();

      setState(() {
        _storeData = response;
        _isOfficial = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오피셜 매장으로 등록되었습니다 🔒')),
        );
      }
    } catch (e) {
      debugPrint("오피셜 등록 실패: $e");
    }
  }

  // ✅ 사진 업로드
  Future<void> _uploadPhoto() async {
    final pickedFiles = await _imagePicker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (pickedFiles.isEmpty || _storeData == null) return;

    setState(() => _isUploadingPhoto = true);

    final storeId = _storeData!['id'];
    List<String> currentPhotos = List<String>.from(_storeData!['photos'] ?? []);

    try {
      for (final picked in pickedFiles) {
        final file = File(picked.path);
        final ext = picked.path.split('.').last;
        final fileName = 'store_$storeId/${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _supabase.storage.from('store-photos').upload(fileName, file);
        final url = _supabase.storage.from('store-photos').getPublicUrl(fileName);
        currentPhotos.add(url);
      }

      await _supabase.from('stores').update({'photos': currentPhotos}).eq('id', storeId);
      await _loadStoreInfo();
    } catch (e) {
      debugPrint("사진 업로드 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 업로드에 실패했습니다.')),
        );
      }
    }

    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  // ✅ 필드 편집
  Future<void> _editField(String fieldName, String label, {bool isArray = false, bool isJsonMenu = false}) async {
    if (_storeData == null || _isOfficial) return;

    final currentValue = _storeData![fieldName];
    String initialText = '';

    if (isJsonMenu && currentValue is List) {
      initialText = currentValue.map((m) => '${m['name']}:${m['price']}').join('\n');
    } else if (isArray && currentValue is List) {
      initialText = currentValue.join('\n');
    } else {
      initialText = (currentValue ?? '').toString();
    }

    final controller = TextEditingController(text: initialText);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('$label 편집', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              _getEditHint(isJsonMenu, isArray),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: isArray || isJsonMenu ? 6 : 2,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F8),
                hintText: isJsonMenu
                    ? '아메리카노:4500\n카페라떼:5000'
                    : isArray ? '한 줄에 하나씩 입력' : '$label을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D3A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    dynamic newValue;
    if (isJsonMenu) {
      newValue = result.split('\n').where((l) => l.contains(':')).map((line) {
        final parts = line.split(':');
        return {'name': parts[0].trim(), 'price': int.tryParse(parts[1].trim()) ?? 0};
      }).toList();
    } else if (isArray) {
      newValue = result.split('\n').where((l) => l.trim().isNotEmpty).toList();
    } else {
      newValue = result;
    }

    try {
      final storeId = _storeData!['id'];
      final userId = _supabase.auth.currentUser?.id;

      await _supabase.from('store_edits').insert({
        'store_id': storeId,
        'user_id': userId,
        'field_name': fieldName,
        'old_value': jsonEncode(currentValue),
        'new_value': jsonEncode(newValue),
      });

      await _supabase.from('stores').update({fieldName: newValue}).eq('id', storeId);
      await _loadStoreInfo();
    } catch (e) {
      debugPrint("필드 수정 실패: $e");
    }
  }

  String _getEditHint(bool isJsonMenu, bool isArray) {
    if (isJsonMenu) return '메뉴명:가격 형식으로 한 줄에 하나씩 입력하세요';
    if (isArray) return '한 줄에 하나씩 입력하세요';
    return '수정할 내용을 입력하세요';
  }

  // ✅ 영업시간 편집
  Future<void> _editHours() async {
    if (_storeData == null) return;
    final currentHours = _storeData!['hours'] is Map ? Map<String, dynamic>.from(_storeData!['hours']) : <String, dynamic>{};

    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final controllers = List.generate(7, (i) => TextEditingController(text: (currentHours[days[i]] ?? '').toString()));

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('영업시간 편집', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...List.generate(7, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(dayNames[i], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        hintText: '09:00-22:00',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F8),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D3A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final newHours = <String, dynamic>{};
    for (int i = 0; i < 7; i++) {
      if (controllers[i].text.trim().isNotEmpty) {
        newHours[days[i]] = controllers[i].text.trim();
      }
    }

    try {
      final storeId = _storeData!['id'];
      final userId = _supabase.auth.currentUser?.id;

      await _supabase.from('store_edits').insert({
        'store_id': storeId,
        'user_id': userId,
        'field_name': 'hours',
        'old_value': jsonEncode(currentHours),
        'new_value': jsonEncode(newHours),
      });

      await _supabase.from('stores').update({'hours': newHours}).eq('id', storeId);
      await _loadStoreInfo();
    } catch (e) {
      debugPrint("영업시간 수정 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(widget.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          // ✅ [피드백 #3] 대시보드 버튼: 오피셜 매장 + (사장 or 관리자) 만 표시
          if (_isOfficial && (_isOwner || _isSuperAdmin))
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Color(0xFF2D2D3A)),
              tooltip: '매장 대시보드',
              onPressed: () => _openDashboard(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D2D3A)))
          : _storeData == null
              ? _buildRegisterPrompt()
              : _buildStoreInfo(),
    );
  }

  // ✅ 매장 정보 없을 때 — 등록 유도
  Widget _buildRegisterPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
              ),
              child: const Icon(Icons.store_mall_directory_outlined, size: 56, color: Color(0xFF2D2D3A)),
            ),
            const SizedBox(height: 24),
            Text(
              '${widget.storeName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              '매장 정보가 아직 등록되지 않았습니다',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // 유저: 직접 등록
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _registerStore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D3A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('매장 정보 등록하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ [피드백 #2] 유저: 운영자에게 오피셜 요청
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _requestOfficialRegistration,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('운영자에게 가게 등록 요청하기', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            ),

            // 관리자: 직접 오피셜 등록
            if (_isSuperAdmin) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _registerAsOfficial,
                  icon: const Icon(Icons.verified, size: 18),
                  label: const Text('오피셜 매장으로 등록 🔒', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C7CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ 매장 정보 표시 — 세련된 디자인
  Widget _buildStoreInfo() {
    final data = _storeData!;
    // Inline editing is disabled in favor of full edit screen
    // final canEdit = !_isOfficial; 

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 오피셜 뱃지
          if (_isOfficial)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D3A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('OFFICIAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.8)),
                ],
              ),
            ),

          // 기본 정보
          _buildCard(children: [
            _buildFieldRow('주소', data['address'] ?? ''),
            _divider(),
            // Legacy 'phone' in db might be 'phone_number'? Check db schema. Usually mapped in select?
            // Note: The select() triggers '*' usually. standard column is 'phone_number'.
            // But code used data['phone']. I will keep it consistent with what I see, but I suspect it might be data['phone_number'].
            // Let's use data['phone_number'] if available fallback to 'phone'
             _buildFieldRow('전화번호', data['phone_number'] ?? data['phone'] ?? ''),
            _divider(),
            _buildFieldRow('카테고리', data['category'] ?? ''),
            _divider(),
            _buildFieldRow('소개', data['description'] ?? ''),
          ]),

          const SizedBox(height: 14),

          // 영업시간
          _buildCard(children: [
            _buildCardHeader('영업시간'),
            const SizedBox(height: 10),
            _buildHoursContent(data['hours'], data['business_hours_data']),
          ]),

          const SizedBox(height: 14),

          // 메뉴
          _buildCard(children: [
            _buildCardHeader('메뉴'),
            const SizedBox(height: 10),
            _buildMenuContent(data['menu']),
          ]),

          const SizedBox(height: 14),

          // 한줄팁
          _buildCard(children: [
            _buildCardHeader('한줄팁'),
            const SizedBox(height: 10),
            _buildTipsContent(data['tips']),
          ]),

          const SizedBox(height: 14),

          // ✅ [피드백 #5] 사진 — 업로드 기능 포함
          _buildCard(children: [
            _buildCardHeader('매장 사진'), // Photo upload is now in Edit Screen
            const SizedBox(height: 10),
            _buildPhotosContent(data['images'] ?? data['photos']), // New column 'images', legacy 'photos'
          ]),

          const SizedBox(height: 14),

          // 편집 이력
          if (_editHistory.isNotEmpty)
            _buildCard(children: [
              _buildCardHeader('편집 이력'),
              const SizedBox(height: 10),
              ..._editHistory.take(5).map((edit) => _buildEditRow(edit)),
            ]),

          // ✅ [피드백 #6] 통계 — 매장 사장만 표시 (슈퍼관리자 X)
          if (_isOwner && _isOfficial) ...[
            const SizedBox(height: 14),
            _buildCard(children: [
              _buildCardHeader('매장 통계'),
              const SizedBox(height: 10),
              _buildStatItem('조회수', '${data['view_count'] ?? 0}'),
              _buildStatItem('클릭수', '${data['click_count'] ?? 0}'),
            ]),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ✅ [피드백 #4] 깔끔한 카드 디자인
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildCardHeader(String title, {VoidCallback? onEdit, VoidCallback? onAdd}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2D2D3A))),
        const Spacer(),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('편집', style: TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
            ),
          ),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 13, color: Color(0xFF666666)),
                  SizedBox(width: 3),
                  Text('추가', style: TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldRow(String label, String value, {String? fieldName, bool canEdit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 13))),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(fontSize: 14, color: value.isEmpty ? const Color(0xFFCCCCCC) : const Color(0xFF2D2D3A)),
            ),
          ),
          if (canEdit && fieldName != null)
            GestureDetector(
              onTap: () => _editField(fieldName, label),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.edit_outlined, size: 15, color: Color(0xFFCCCCCC)),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ 매장 수정 화면으로 이동
  Future<void> _openEditStore() async {
    if (_storeData == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreEditScreen(storeData: _storeData!),
      ),
    );

    if (result == true) {
      _loadStoreInfo();
    }
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[100]);

  Widget _buildHoursContent(dynamic hours, [dynamic newHours]) {
    // 1. New Structured Data Support
    if (newHours != null && newHours is Map && newHours.isNotEmpty) {
      final open = newHours['open'] ?? '';
      final close = newHours['close'] ?? '';
      final breakStart = newHours['break_start'];
      final breakEnd = newHours['break_end'];
      final holidays = newHours['holidays'];
      final days = newHours['days'] as List?;
      
      final dayLabels = {'mon':'월', 'tue':'화', 'wed':'수', 'thu':'목', 'fri':'금', 'sat':'토', 'sun':'일'};
      String daysText = '매일';
      if (days != null && days.length < 7) {
        daysText = days.map((d) => dayLabels[d] ?? '').join(', ');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconText(Icons.access_time_filled, '$open ~ $close', const Color(0xFF2D2D3A)),
          if (breakStart != null && breakEnd != null)
             Padding(
               padding: const EdgeInsets.only(top: 4),
               child: _buildIconText(Icons.free_breakfast_outlined, '브레이크타임: $breakStart ~ $breakEnd', const Color(0xFF555555)),
             ),
          if (holidays != null && holidays.toString().isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 4),
               child: _buildIconText(Icons.calendar_today_outlined, '휴무: $holidays', Colors.redAccent),
             ),
          const SizedBox(height: 8),
          Text(
            '운영 요일: $daysText', 
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ],
      );
    }

    // 2. Legacy Support
    if (hours == null || (hours is Map && hours.isEmpty)) {
      return Text('영업시간 정보가 없습니다.', style: TextStyle(color: Colors.grey[400], fontSize: 13));
    }

    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final hoursMap = hours is Map ? hours : {};

    return Column(
      children: List.generate(7, (i) {
        final h = hoursMap[days[i]];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text(dayNames[i], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D2D3A)))),
              const SizedBox(width: 16),
              Text(h?.toString() ?? '-', style: TextStyle(fontSize: 13, color: h != null ? const Color(0xFF555555) : const Color(0xFFCCCCCC))),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _buildMenuContent(dynamic menu) {
    if (menu == null || (menu is List && menu.isEmpty)) {
      return Text('메뉴 정보가 없습니다.', style: TextStyle(color: Colors.grey[400], fontSize: 13));
    }

    final menuList = menu is List ? menu : [];
    
    return Column(
      children: menuList.map<Widget>((item) {
        final m = item is Map ? item : {};
        final photoUrl = m['photo_url'];
        final hasPhoto = photoUrl != null && photoUrl.toString().isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              if (hasPhoto)
                Container(
                  width: 60, height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['name']?.toString() ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A))),
                    const SizedBox(height: 2),
                    Text(
                      m['price'] != null ? '${_formatPrice(m['price'])}원' : '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8A2BE2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatPrice(dynamic price) {
    final p = price is int ? price : int.tryParse(price.toString()) ?? 0;
    return p.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Widget _buildTipsContent(dynamic tips) {
    if (tips == null || (tips is List && tips.isEmpty)) {
      return Text('등록된 팁이 없습니다.', style: TextStyle(color: Colors.grey[400], fontSize: 13));
    }

    final tipList = tips is List ? tips : [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tipList.map<Widget>((tip) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4, height: 4,
                decoration: const BoxDecoration(color: Color(0xFF2D2D3A), shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(tip.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotosContent(dynamic photos) {
    if (photos == null || (photos is List && photos.isEmpty)) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, color: Color(0xFFCCCCCC), size: 28),
              SizedBox(height: 4),
              Text('아직 등록된 사진이 없습니다', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final photoList = photos is List ? photos : [];
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              photoList[index].toString(),
              width: 120, height: 120, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 120, color: const Color(0xFFF5F5F8),
                child: const Icon(Icons.broken_image, color: Color(0xFFCCCCCC)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditRow(Map<String, dynamic> edit) {
    final nickname = edit['profiles']?['nickname'] ?? '익명';
    final field = edit['field_name'] ?? '';
    final createdAt = edit['created_at']?.toString().substring(0, 10) ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: const Color(0xFFF0F0F3), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_note, size: 12, color: Color(0xFF999999)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$nickname님이 $field을(를) 수정',
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ),
          Text(createdAt, style: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D2D3A))),
        ],
      ),
    );
  }

  void _openDashboard() {
    if (_storeData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StoreDashboardPage(
          storeId: _storeData!['id'],
          storeName: widget.storeName,
        ),
      ),
    );
  }
}

// =============================================
// 매장 대시보드 (사장님 전용)
// =============================================
class _StoreDashboardPage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const _StoreDashboardPage({required this.storeId, required this.storeName});

  @override
  State<_StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<_StoreDashboardPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  int _viewCount = 0;
  int _clickCount = 0;
  int _saveCount = 0;
  int _reviewCount = 0;
  double _avgScore = 0.0;
  List<Map<String, dynamic>> _recentReviews = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final storeData = await _supabase
          .from('stores')
          .select('view_count, click_count')
          .eq('id', widget.storeId)
          .single();

      _viewCount = storeData['view_count'] ?? 0;
      _clickCount = storeData['click_count'] ?? 0;

      final saves = await _supabase
          .from('store_saves')
          .select('id')
          .eq('store_name', widget.storeName);
      _saveCount = (saves is List) ? saves.length : 0;

      final reviews = await _supabase
          .from('reviews')
          .select('needsfine_score, created_at, content, is_hidden')
          .eq('store_name', widget.storeName)
          .order('created_at', ascending: false);

      final reviewList = (reviews is List) ? reviews : [];
      final visibleReviews = reviewList.where((r) => r['is_hidden'] != true).toList();

      _reviewCount = visibleReviews.length;
      if (visibleReviews.isNotEmpty) {
        final totalScore = visibleReviews.fold<double>(0, (sum, r) {
          final s = r['needsfine_score'];
          return sum + (s is num ? s.toDouble() : 0);
        });
        _avgScore = totalScore / visibleReviews.length;
      }

      _recentReviews = visibleReviews.take(10).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint("대시보드 데이터 로드 실패: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text('${widget.storeName} 대시보드', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D2D3A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D2D3A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildStatCard('조회수', '$_viewCount', Icons.visibility_outlined),
                      _buildStatCard('클릭수', '$_clickCount', Icons.touch_app_outlined),
                      _buildStatCard('저장수', '$_saveCount', Icons.bookmark_outline),
                      _buildStatCard('리뷰수', '$_reviewCount', Icons.rate_review_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        const Text('평균 NeedsFine 점수', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(_avgScore.toStringAsFixed(1), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('최근 리뷰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
                  const SizedBox(height: 10),
                  if (_recentReviews.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('아직 리뷰가 없습니다.', style: TextStyle(color: Color(0xFF999999)))))
                  else
                    ...(_recentReviews.map((review) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(review['needsfine_score'] is num ? (review['needsfine_score'] as num).toStringAsFixed(1) : '0.0')}점',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A)),
                              ),
                              Text(review['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review['content']?.toString() ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                          ),
                        ],
                      ),
                    ))),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF2D2D3A), size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}
