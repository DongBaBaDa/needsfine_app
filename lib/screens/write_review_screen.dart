import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/services/score_calculator.dart';
import 'package:needsfine_app/widgets/feedback_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';
// ✅ 압축 및 경로 관련 패키지
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _reviewTextController = TextEditingController();

  double _rating = 0;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  // 실시간 피드백용 (서버 저장용 아님, 사용자에게 보여주기만 하는 용도)
  Map<String, dynamic> get _calculatedScore {
    if (_reviewTextController.text.trim().isEmpty || _rating == 0) return {};
    return ScoreCalculator.calculateNeedsFineScore(
      _reviewTextController.text,
      _rating,
      _selectedImages.isNotEmpty,
    );
  }

  // ✅ 1. 사진 선택 및 자동 압축 로직
  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 5장까지 첨부 가능합니다')));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 압축 실행
      File? compressedFile = await _compressImage(File(image.path));

      if (compressedFile != null) {
        setState(() => _selectedImages.add(compressedFile));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사진 처리에 실패했습니다.')));
      }
    }
  }

  // ✅ 2. 이미지 압축 헬퍼 함수
  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final name = const Uuid().v4();
      final targetPath = '$path/$name.jpg';

      // 500KB 이하 목표 (화질 70%, 해상도 1024px 제한)
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint("이미지 압축 오류: $e");
      return null;
    }
  }

  // ✅ 3. 리뷰 등록 (Edge Function이 계산하도록 원본 데이터만 전송)
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('별점을 선택해주세요')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final photoUrls = <String>[];
      final supabase = Supabase.instance.client;
      final userId = await ReviewService.getUserId() ?? 'anonymous';

      // 3-1. 사진 업로드
      for (final image in _selectedImages) {
        final fileExt = 'jpg'; // 압축해서 jpg로 통일됨
        final fileName = '${const Uuid().v4()}.$fileExt';
        final filePath = '$userId/$fileName'; // 폴더 구조: 유저ID/파일명

        // Storage 버킷 이름 확인 필요 (review_photos vs review-photos)
        // 여기서는 에러가 덜 나는 review_photos(언더바)로 작성합니다.
        await supabase.storage.from('review_photos').upload(
          filePath,
          image,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

        final imageUrl = supabase.storage.from('review_photos').getPublicUrl(filePath);
        photoUrls.add(imageUrl);
      }

      // 3-2. 데이터 저장 요청
      // Edge Function이 있으므로 점수 계산 없이 순수 데이터만 보냅니다.
      await ReviewService.createReview(
        storeName: _storeNameController.text.trim(),
        reviewText: _reviewTextController.text.trim(),
        userRating: _rating,
        photoUrls: photoUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('리뷰가 등록되었습니다! (점수는 잠시 후 집계됩니다)'),
          backgroundColor: Color(0xFF9C7CFF),
        ),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if(mounted) {
        String errorMessage = '리뷰 등록 실패: $e';
        // 자주 발생하는 Storage 에러 처리
        if (e.toString().contains('Bucket not found')) {
          errorMessage = '서버 저장소 이름을 확인해주세요. (review_photos)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF0E9FF),
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        backgroundColor: const Color(0xFF9C7CFF),
        actions: [
          NotificationBadge(
            iconColor: Colors.white,
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('가게 이름을 입력해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  hintText: '예: 맛있는 파스타집',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9C7CFF))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF9C7CFF).withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9C7CFF), width: 2)),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? '가게 이름을 입력해주세요' : null,
              ),
              const SizedBox(height: 24),
              const Text('리뷰를 작성해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.2))),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('아래 가이드에 맞춰 작성하면 더 정확한 평가가 가능해요!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('• 맛, 가격, 분위기 등 솔직한 경험을 공유해주세요.', style: TextStyle(fontSize: 12)),
                  Text('• 사진을 첨부하면 신뢰도가 더 올라가요! 📸', style: TextStyle(fontSize: 12, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reviewTextController,
                maxLines: 6,
                maxLength: 200, // ✅ 글자수 200자 제한 적용
                decoration: InputDecoration(
                  hintText: '솔직한 경험을 자세히 작성해주세요... (최대 200자)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF9C7CFF).withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9C7CFF), width: 2)),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => (value == null || value.trim().isEmpty) ? '리뷰 내용을 입력해주세요' : null,
              ),

              const SizedBox(height: 24),
              const Text('별점을 선택해주세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return GestureDetector(
                      onTapDown: (details) {
                        final dx = details.localPosition.dx;
                        final width = 40.0;
                        if (dx < width / 2) {
                          setState(() => _rating = starNum - 0.5);
                        } else {
                          setState(() => _rating = starNum.toDouble());
                        }
                      },
                      child: Icon(
                        _rating >= starNum ? Icons.star : (_rating == starNum - 0.5 ? Icons.star_half : Icons.star_border),
                        size: 40,
                        color: _rating >= starNum - 0.5 ? const Color(0xFF9C7CFF) : Colors.grey[300],
                      ),
                    );
                  }),
                ),
              ),
              if (_rating > 0) Padding(padding: const EdgeInsets.only(top: 12.0), child: Center(child: Text('선택한 별점: ${_rating.toStringAsFixed(1)}점', style: const TextStyle(fontSize: 18, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)))),
              const SizedBox(height: 24),

              // 사진 첨부 버튼
              ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: Text('사진 첨부 (${_selectedImages.length}/5)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF9C7CFF), minimumSize: const Size(double.infinity, 48))
              ),

              // 선택된 사진 미리보기
              if (_selectedImages.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12.0), child: Wrap(spacing: 8, runSpacing: 8, children: _selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover)),
                  Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _selectedImages.removeAt(index)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                ]);
              }).toList())),

              const SizedBox(height: 24),
              // 실시간 피드백 (화면 표시용)
              if (_calculatedScore.isNotEmpty) ...[const Text('📊 실시간 피드백', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)), const SizedBox(height: 16), FeedbackIndicator(calculatedScore: _calculatedScore), const SizedBox(height: 24)],

              // 등록 버튼
              ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C7CFF), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('리뷰 등록하기')
              ),

              // ✅ 스크롤 여백 추가
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _reviewTextController.dispose();
    super.dispose();
  }
}