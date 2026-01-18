import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/services/score_calculator.dart';
import 'package:needsfine_app/services/naver_search_service.dart'; // 검색 서비스
import 'package:needsfine_app/widgets/feedback_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewTextController = TextEditingController();
  final _searchController = TextEditingController(); // 가게 검색용 컨트롤러

  // 검색 관련 상태
  final NaverSearchService _naverSearchService = NaverSearchService();
  NaverPlace? _selectedPlace; // 선택된 가게 정보

  double _rating = 0;
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  // 실시간 피드백 (v11.1 Logic)
  Map<String, dynamic> get _calculatedScore {
    if (_reviewTextController.text.trim().isEmpty || _rating == 0) return {};
    return ScoreCalculator.calculateNeedsFineScore(
      _reviewTextController.text,
      _rating,
      _selectedImages.isNotEmpty,
    );
  }

  // ✅ 가게 검색 모달 열기
  void _showStoreSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: 600,
            child: _StoreSearchContent(
              onPlaceSelected: (place) {
                setState(() {
                  _selectedPlace = place;
                });
                Navigator.pop(context);
              },
              searchService: _naverSearchService,
            ),
          ),
        );
      },
    );
  }

  // ✅ 이미지 선택 및 압축
  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 5장까지 첨부 가능합니다')));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File? compressedFile = await _compressImage(File(image.path));
      if (compressedFile != null) {
        setState(() => _selectedImages.add(compressedFile));
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final name = const Uuid().v4();
      final targetPath = '$path/$name.jpg';

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

  // ✅ 리뷰 등록
  Future<void> _submitReview() async {
    if (_selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가게를 검색해서 선택해주세요')));
      return;
    }
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

      // 1. 사진 업로드
      for (final image in _selectedImages) {
        final fileName = '${const Uuid().v4()}.jpg';
        final filePath = '$userId/$fileName';
        await supabase.storage.from('review_photos').upload(
          filePath,
          image,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        final imageUrl = supabase.storage.from('review_photos').getPublicUrl(filePath);
        photoUrls.add(imageUrl);
      }

      // 2. 리뷰 저장
      // NaverPlace의 상세 정보를 활용 (주소, 좌표 등은 DB 스키마에 따라 추가 가능)
      await ReviewService.createReview(
        storeName: _selectedPlace!.cleanTitle, // HTML 태그 제거된 이름
        reviewText: _reviewTextController.text.trim(),
        userRating: _rating,
        photoUrls: photoUrls,
        // TODO: 필요한 경우 address, mapx, mapy 등 추가 필드 전달
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('리뷰가 등록되었습니다!'),
          backgroundColor: Color(0xFF9C7CFF),
        ),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('리뷰 등록 실패: $e')));
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
              // 1. 가게 검색 섹션
              const Text('어떤 가게를 다녀오셨나요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (_selectedPlace == null)
                GestureDetector(
                  onTap: _showStoreSearchSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Color(0xFF9C7CFF)),
                        SizedBox(width: 10),
                        Text('가게 이름 검색하기', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
              // 선택된 가게 정보 카드
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF9C7CFF), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFF0E9FF), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.store, color: Color(0xFF9C7CFF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedPlace!.cleanTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(_selectedPlace!.roadAddress.isNotEmpty ? _selectedPlace!.roadAddress : _selectedPlace!.address, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_selectedPlace!.category, style: const TextStyle(fontSize: 11, color: Color(0xFF9C7CFF))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _selectedPlace = null),
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              const Text('리뷰를 작성해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.2))),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('팁: 구체적인 메뉴 이름과 분위기를 적으면 점수가 올라가요!', style: TextStyle(fontSize: 12, color: Colors.deepPurple)),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reviewTextController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: '솔직한 경험을 자세히 작성해주세요... (최대 500자)',
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

              // 사진 첨부
              ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: Text('사진 첨부 (${_selectedImages.length}/5)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF9C7CFF), minimumSize: const Size(double.infinity, 48))
              ),
              if (_selectedImages.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12.0), child: Wrap(spacing: 8, runSpacing: 8, children: _selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover)),
                  Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _selectedImages.removeAt(index)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                ]);
              }).toList())),

              const SizedBox(height: 24),
              // 실시간 피드백
              if (_calculatedScore.isNotEmpty) ...[
                const Text('📊 실시간 분석', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FeedbackIndicator(calculatedScore: _calculatedScore),
                const SizedBox(height: 24)
              ],

              ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C7CFF), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('리뷰 등록하기')
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 내부 위젯: 검색 모달용 컨텐츠
// -----------------------------------------------------------------------------
class _StoreSearchContent extends StatefulWidget {
  final Function(NaverPlace) onPlaceSelected;
  final NaverSearchService searchService;

  const _StoreSearchContent({required this.onPlaceSelected, required this.searchService});

  @override
  State<_StoreSearchContent> createState() => _StoreSearchContentState();
}

class _StoreSearchContentState extends State<_StoreSearchContent> {
  final _controller = TextEditingController();
  List<NaverPlace> _results = [];
  bool _isLoading = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final results = await widget.searchService.searchPlaces(query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '가게 이름 검색 (예: 강남역 파스타)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('검색', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
              ? const Center(child: Text("검색 결과가 없습니다."))
              : ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final place = _results[index];
              return ListTile(
                title: Text(place.cleanTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(place.roadAddress.isNotEmpty ? place.roadAddress : place.address),
                trailing: Text(place.category.split('>').last, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () => widget.onPlaceSelected(place),
              );
            },
          ),
        ),
      ],
    );
  }
}