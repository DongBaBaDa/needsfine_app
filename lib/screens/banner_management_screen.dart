import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // ✅ 동적 배너 리스트 (초기값 비어있음)
  List<Map<String, dynamic>> _bannerList = [];

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  // 1. 배너 목록 불러오기
  Future<void> _fetchBanners() async {
    setState(() => _isLoading = true);
    try {
      // 등록된 순서(created_at)대로 가져옴
      final data = await _supabase
          .from('banners')
          .select('id, image_url')
          .order('created_at', ascending: true);

      setState(() {
        _bannerList = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('배너 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. 이미지 선택 및 업로드 (카메라/갤러리 선택 모달)
  Future<void> _showImagePicker() async {
    if (_bannerList.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("배너는 최대 7개까지만 등록 가능합니다.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("갤러리에서 선택"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("카메라로 촬영"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. 실제 업로드 로직
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // 용량 최적화
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      // Storage 업로드
      await _supabase.storage.from('banners').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // URL 가져오기
      final imageUrl = _supabase.storage.from('banners').getPublicUrl(filePath);

      // DB Insert (position 없이 저장 -> SQL에서 nullable로 변경했으므로 성공함)
      await _supabase.from('banners').insert({
        'image_url': imageUrl,
      });

      // 목록 갱신
      await _fetchBanners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("배너가 추가되었습니다.")));
      }

    } catch (e) {
      debugPrint('업로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("오류 발생: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. 배너 삭제
  Future<void> _deleteBanner(String id, int index) async {
    try {
      setState(() => _isLoading = true);

      // DB 삭제
      await _supabase.from('banners').delete().eq('id', id);

      // 리스트에서 즉시 제거
      setState(() {
        _bannerList.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("배너가 삭제되었습니다.")));
      }
    } catch (e) {
      debugPrint('삭제 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("배너 관리", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideSection(),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "등록된 배너 (${_bannerList.length}/7)",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ 등록된 배너 리스트 (없으면 표시 안 함)
          if (_bannerList.isNotEmpty)
            ...List.generate(_bannerList.length, (index) {
              final banner = _bannerList[index];
              return _buildBannerItem(index, banner);
            })
          else
            _buildEmptyState(),

          // ✅ [+ 배너 추가하기] 버튼 (7개 미만일 때만 표시)
          if (_bannerList.length < 7)
            _buildAddButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const Text(
        "등록된 배너가 없습니다.\n아래 버튼을 눌러 배너를 추가해주세요.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text("배너 등록 가이드", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("• 권장 비율: 2.4 : 1 (가로 : 세로)"),
          const Text("• 권장 해상도: 1080px × 450px"),
          const Text("• 파일 형식: JPG, PNG"),
        ],
      ),
    );
  }

  Widget _buildBannerItem(int index, Map<String, dynamic> banner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("배너 #${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteBanner(banner['id'], index),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 2.4,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  banner['image_url'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showImagePicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8A2BE2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Color(0xFF8A2BE2)),
            SizedBox(width: 8),
            Text(
                "배너 추가하기",
                style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ],
        ),
      ),
    );
  }
}