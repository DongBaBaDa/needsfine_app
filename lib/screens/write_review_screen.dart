// lib/screens/write_review_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/services/score_calculator.dart';
import 'package:needsfine_app/widgets/feedback_indicator.dart';

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
  double _hoverRating = 0;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  // 실시간 점수 계산
  Map<String, dynamic> get _calculatedScore {
    if (_reviewTextController.text.trim().isEmpty || _rating == 0) {
      return {};
    }
    return ScoreCalculator.calculateNeedsFineScore(
      _reviewTextController.text,
      _rating,
      _selectedImages.isNotEmpty,
    );
  }

  // 이미지 선택
  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 5장까지 첨부 가능합니다')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  // 리뷰 제출
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: 이미지 업로드 로직 (Supabase Storage)
      final photoUrls = <String>[]; // 업로드 후 URL 리스트

      await ReviewService.createReview(
        storeName: _storeNameController.text.trim(),
        reviewText: _reviewTextController.text.trim(),
        userRating: _rating,
        photoUrls: photoUrls,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('리뷰가 성공적으로 등록되었습니다! 🎉'),
          backgroundColor: Color(0xFF9C7CFF),
        ),
      );

      Navigator.pop(context, true); // 성공 시 화면 닫기
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0E9FF),
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        backgroundColor: const Color(0xFF9C7CFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 가게 이름
              const Text(
                '가게 이름을 입력해주세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  hintText: '예: 맛있는 파스타집',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9C7CFF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF9C7CFF).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9C7CFF), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '가게 이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 리뷰 내용
              const Text(
                '리뷰를 작성해주세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '아래 가이드에 맞춰 작성하면 더 정확한 평가가 가능해요!',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text('• 맛은 어땠나요? (혹은 인상 깊은 메뉴가 있었나요?)', style: TextStyle(fontSize: 12)),
                    Text('• 가격 대비 만족도는 어땠나요?', style: TextStyle(fontSize: 12)),
                    Text('• 분위기·서비스에서 기억나는 점이 있나요?', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reviewTextController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '솔직한 경험을 자세히 작성해주세요...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF9C7CFF).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9C7CFF), width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}), // 실시간 업데이트
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '리뷰 내용을 입력해주세요';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '현재 ${_reviewTextController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length}단어',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 24),

              // 별점 선택
              const Text(
                '별점을 선택해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    final currentRating = _hoverRating > 0 ? _hoverRating : _rating;
                    final isFull = currentRating >= starNum;
                    final isHalf = currentRating == starNum - 0.5;

                    return GestureDetector(
                      onTapDown: (details) {
                        final dx = details.localPosition.dx;
                        final width = 40.0; // 별 크기
                        if (dx < width / 2) {
                          setState(() => _rating = starNum - 0.5);
                        } else {
                          setState(() => _rating = starNum.toDouble());
                        }
                      },
                      child: Icon(
                        isFull ? Icons.star : (isHalf ? Icons.star_half : Icons.star_border),
                        size: 40,
                        color: isFull || isHalf ? const Color(0xFF9C7CFF) : Colors.grey[300],
                      ),
                    );
                  }),
                ),
              ),
              if (_rating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: Text(
                      '선택한 별점: ${_rating.toStringAsFixed(1)}점',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF9C7CFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 📸 사진 첨부
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text('사진 첨부 (${_selectedImages.length}/5)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9C7CFF),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              if (_selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedImages.removeAt(index));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // 📊 실시간 피드백
              if (_calculatedScore.isNotEmpty) ...[
                const Text(
                  '📊 실시간 피드백',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF9C7CFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FeedbackIndicator(calculatedScore: _calculatedScore),
                const SizedBox(height: 24),
              ],

              // 제출 버튼
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C7CFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('리뷰 등록하기'),
              ),
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
