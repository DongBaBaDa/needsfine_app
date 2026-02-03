import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:needsfine_app/services/review_service.dart';
// ✅ ScoreCalculator 경로가 utils인지 services인지 파일 위치를 꼭 확인하세요.
import 'package:needsfine_app/utils/score_calculator.dart';
import 'package:needsfine_app/services/naver_search_service.dart';
import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/models/ranking_models.dart' as model;
import 'package:needsfine_app/widgets/notification_badge.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/core/profanity_filter.dart';

class WriteReviewScreen extends StatefulWidget {
  final String? initialStoreName;
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;
  final model.Review? reviewToEdit;

  const WriteReviewScreen({
    super.key,
    this.initialStoreName,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
    this.reviewToEdit,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reviewTextController;

  final NaverSearchService _naverSearchService = NaverSearchService();
  final NaverGeocodingService _geocodingService = NaverGeocodingService();

  NaverPlace? _selectedPlace;
  double? _selectedLat;
  double? _selectedLng;

  double _rating = 0;

  List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  bool _isSubmitting = false;
  bool _isInitialData = false;
  bool _isEditMode = false;

  // ✅ 태그 데이터 (홈 화면 검색과 일치)
  final Map<String, List<String>> _tagCategories = {
    '혼자서 👤': ['혼밥', '힐링', '가성비', '브런치', '포장가능', '조용한', '간편한'],
    '둘이서 👩‍❤️‍👨': ['데이트', '기념일', '분위기맛집', '뷰맛집', '이색요리', '와인', '코스요리'],
    '여럿이 👨‍👩‍👧‍👦': ['회식', '가족모임', '친구모임', '주차가능', '룸있음', '대화하기좋은', '넓은좌석'],
  };

  // ✅ 현재 선택된 태그 카테고리 (기본값: 혼자서)
  String _currentTab = '혼자서 👤';
  final Set<String> _selectedTags = {};

  // ✅ 실시간 분석 상태
  double _predictedScore = 0.0;
  int _predictedTrust = 0;
  String _feedbackMessage = "가장 기억에 남는 맛은 무엇이었나요?";
  bool _isFeedbackWarning = false;
  bool _showAnalysis = false;

  // 디자인 토큰
  static const Color _brand = Color(0xFF8A2BE2);
  static const Color _bg = Color(0xFFF2F2F7);

  @override
  void initState() {
    super.initState();
    _reviewTextController = TextEditingController();

    if (widget.reviewToEdit != null) {
      _isEditMode = true;
      _isInitialData = true;

      final r = widget.reviewToEdit!;
      _reviewTextController.text = r.reviewText;
      _rating = r.userRating;
      _existingImageUrls = List.from(r.photoUrls);
      _selectedTags.addAll(r.tags);

      _selectedPlace = NaverPlace(
        title: r.storeName,
        category: '음식점',
        address: r.storeAddress ?? '',
        roadAddress: r.storeAddress ?? '',
      );
      _selectedLat = r.storeLat;
      _selectedLng = r.storeLng;

      // 초기 데이터가 있으면 바로 분석 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzeRealTime();
      });

    } else if (widget.initialStoreName != null && widget.initialAddress != null) {
      _selectedPlace = NaverPlace(
        title: widget.initialStoreName!,
        category: '음식점',
        address: widget.initialAddress!,
        roadAddress: widget.initialAddress!,
      );
      _selectedLat = widget.initialLat;
      _selectedLng = widget.initialLng;
      _isInitialData = true;
    }
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  // ✅ [수정됨] 실시간 분석 및 피드백 생성
  void _analyzeRealTime() {
    final text = _reviewTextController.text.trim();
    bool hasImages = _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;
    double inputRating = _rating == 0 ? 3.0 : _rating;

    try {
      // 1. 점수 계산
      final result = ScoreCalculator.calculateNeedsFineScore(text, inputRating, hasImages);

      // 2. 피드백 메시지 생성
      final feedback = ScoreCalculator.getFeedbackMessage(result);

      setState(() {
        _predictedScore = (result['needsfine_score'] as num).toDouble();
        _predictedTrust = (result['trust_level'] as num).toInt();
        _feedbackMessage = feedback['message'];
        _isFeedbackWarning = feedback['is_warning'];

        // ⚡ [수정 포인트] 글자가 1자라도 있으면 바로 보이게 변경 (기존: > 5)
        _showAnalysis = text.isNotEmpty;
      });

      // 디버깅용: 콘솔에 찍히는지 확인하세요
      print('실시간 분석 중: $_predictedScore점 / 신뢰도 $_predictedTrust%');

    } catch (e) {
      print('ScoreCalculator 오류 발생: $e');
    }
  }

  void _showStoreSearchSheet() {
    if (_isInitialData) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Expanded(
                child: _StoreSearchContent(
                  searchService: _naverSearchService,
                  onPlaceSelected: (place) async {
                    double? lat, lng;
                    try {
                      final addr = place.roadAddress.isNotEmpty ? place.roadAddress : place.address;
                      if (addr.isNotEmpty) {
                        final response = await _geocodingService.searchAddress(addr);
                        if (response.addresses.isNotEmpty) {
                          lat = double.tryParse(response.addresses.first.y);
                          lng = double.tryParse(response.addresses.first.x);
                        }
                      }
                    } catch(e) {
                      debugPrint("좌표 변환 실패: $e");
                    }

                    if (mounted) {
                      setState(() {
                        _selectedPlace = place;
                        _selectedLat = lat;
                        _selectedLng = lng;
                        _isInitialData = false;
                      });
                    }
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    if ((_newImages.length + _existingImageUrls.length) >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 5장까지 첨부 가능합니다')));
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File? compressedFile = await _compressImage(File(image.path));
      if (compressedFile != null) {
        setState(() => _newImages.add(compressedFile));
        _analyzeRealTime();
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
        file.absolute.path, targetPath, quality: 70, minWidth: 1024, minHeight: 1024,
      );
      return result != null ? File(result.path) : null;
    } catch (e) { return null; }
  }

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

    if (ProfanityFilter.hasProfanity(_reviewTextController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("부적절한 단어가 포함되어 있어 등록할 수 없습니다."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = await ReviewService.getUserId() ?? 'anonymous';

      final uploadedPhotoUrls = <String>[];
      for (final image in _newImages) {
        final fileName = '${const Uuid().v4()}.jpg';
        final filePath = '$userId/$fileName';
        await supabase.storage.from('review_photos').upload(filePath, image, fileOptions: const FileOptions(contentType: 'image/jpeg'));
        final imageUrl = supabase.storage.from('review_photos').getPublicUrl(filePath);
        uploadedPhotoUrls.add(imageUrl);
      }

      final finalPhotoUrls = [..._existingImageUrls, ...uploadedPhotoUrls];
      final List<String> tags = _selectedTags.toList();

      if (_isEditMode) {
        await ReviewService.updateReview(
          reviewId: widget.reviewToEdit!.id,
          content: _reviewTextController.text.trim(),
          rating: _rating,
          photoUrls: finalPhotoUrls,
          tags: tags,
        );
      } else {
        await ReviewService.createReview(
          storeName: _selectedPlace!.cleanTitle,
          storeAddress: _selectedPlace!.roadAddress.isNotEmpty ? _selectedPlace!.roadAddress : _selectedPlace!.address,
          reviewText: _reviewTextController.text.trim(),
          userRating: _rating,
          photoUrls: finalPhotoUrls,
          lat: _selectedLat,
          lng: _selectedLng,
          tags: tags,
        );
      }

      if (!mounted) return;

      if (_selectedLat != null && _selectedLng != null) {
        searchTrigger.value = SearchTarget(
          query: _selectedPlace!.cleanTitle,
          lat: _selectedLat,
          lng: _selectedLng,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEditMode ? '리뷰가 수정되었습니다!' : '리뷰가 등록되었습니다!'),
            backgroundColor: const Color(0xFF9C7CFF)
        ),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ✅ [수정] 태그 카테고리 탭 UI (횡스크롤)
  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tagCategories.keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _tagCategories.keys.elementAt(index);
          final isSelected = _currentTab == category;
          return GestureDetector(
            onTap: () => setState(() => _currentTab = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _brand : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _brand : Colors.grey.shade300),
                boxShadow: isSelected ? [BoxShadow(color: _brand.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))] : [],
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ [수정] 세부 태그 UI (횡스크롤 1줄)
  Widget _buildSubTags() {
    final tags = _tagCategories[_currentTab] ?? [];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = _selectedTags.contains(tag);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedTags.remove(tag);
                } else {
                  _selectedTags.add(tag);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _brand.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _brand : Colors.grey.shade300),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: isSelected ? _brand : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEditMode ? '리뷰 수정' : '리뷰 작성',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          NotificationBadge(onTap: () => Navigator.pushNamed(context, '/notifications')),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 가게 선택 (디자인 유지)
              if (_selectedPlace == null)
                GestureDetector(
                  onTap: _showStoreSearchSheet,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.search_rounded, size: 32, color: _brand),
                        const SizedBox(height: 12),
                        const Text("방문한 맛집을 찾아주세요", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("정확한 장소 선택이 신뢰도의 시작입니다", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: _brand.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.store_rounded, color: _brand),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedPlace!.cleanTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(
                              _selectedPlace!.roadAddress.isNotEmpty ? _selectedPlace!.roadAddress : _selectedPlace!.address,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!_isInitialData)
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
                          onPressed: () => setState(() { _selectedPlace = null; _selectedLat = null; _selectedLng = null; }),
                        )
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // 2. 별점 선택
              Center(
                child: Column(
                  children: [
                    const Text("전반적인 경험은 어떠셨나요?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNum = index + 1;
                        return GestureDetector(
                          onTapDown: (details) {
                            final dx = details.localPosition.dx;
                            final width = 48.0;
                            if (dx < width / 2) setState(() => _rating = starNum - 0.5); else setState(() => _rating = starNum.toDouble());
                            _analyzeRealTime();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              _rating >= starNum ? Icons.star_rounded : (_rating == starNum - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
                              size: 48,
                              color: _rating >= starNum - 0.5 ? const Color(0xFFFFD700) : Colors.grey[300],
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_rating > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${_rating.toStringAsFixed(1)}점',
                          style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ✅ 3. 방문 목적 태그 (수정됨: 횡스크롤 탭 + 횡스크롤 태그)
              const Text("이곳의 특징을 선택해주세요", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _buildCategoryTabs(), // 상단 카테고리
              const SizedBox(height: 16),
              _buildSubTags(), // 하단 태그

              const SizedBox(height: 24),

              // 4. 리뷰 입력 및 분석 대시보드
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextFormField(
                            controller: _reviewTextController,
                            maxLines: 8,
                            maxLength: 500,
                            style: const TextStyle(fontSize: 15, height: 1.6),
                            decoration: InputDecoration(
                              hintText: '메뉴의 맛, 매장의 분위기, 직원 서비스 등\n솔직한 경험을 공유해주세요.',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            onChanged: (_) => _analyzeRealTime(),
                            validator: (value) => (value == null || value.trim().isEmpty) ? '내용을 입력해주세요' : null,
                          ),
                        ),

                        // ✅ [수정] 실시간 분석 피드백 대시보드
                        if (_showAnalysis)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isFeedbackWarning
                                    ? [const Color(0xFFFF8A80), const Color(0xFFFF5252)] // 경고 시 붉은색 톤
                                    : [const Color(0xFF8A2BE2), const Color(0xFF9C7CFF)], // 평소 보라색 톤
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                              boxShadow: [
                                BoxShadow(color: _brand.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildScoreMetric("예상 점수", _predictedScore.toStringAsFixed(1), true),
                                    Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
                                    _buildScoreMetric("신뢰도", "$_predictedTrust%", false),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                          _isFeedbackWarning ? Icons.warning_amber_rounded : Icons.auto_awesome,
                                          color: Colors.white, size: 20
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _feedbackMessage,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. 사진 첨부
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_rounded, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text("${_newImages.length + _existingImageUrls.length}/5", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    ..._existingImageUrls.asMap().entries.map((entry) => _buildPhotoItem(entry.value, true, entry.key)),
                    ..._newImages.asMap().entries.map((entry) => _buildPhotoItem(entry.value, false, entry.key)),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(_isEditMode ? '수정 완료' : '리뷰 등록하기')
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreMetric(String label, String value, bool isScore) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoItem(dynamic imageSource, bool isNetwork, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: isNetwork
                ? Image.network(imageSource, fit: BoxFit.cover, height: 100)
                : Image.file(imageSource, fit: BoxFit.cover, height: 100),
          ),
        ),
        Positioned(
          top: 4, right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() => isNetwork ? _existingImageUrls.removeAt(index) : _newImages.removeAt(index));
              _analyzeRealTime();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

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
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.searchService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("검색 에러: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("어디를 다녀오셨나요?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: '가게 이름 검색 (예: 스타벅스)',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF8A2BE2)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2)))
              : _results.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.store_mall_directory_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final place = _results[index];
              return GestureDetector(
                onTap: () => widget.onPlaceSelected(place),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.place_rounded, color: Color(0xFF8A2BE2), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.cleanTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              place.roadAddress.isNotEmpty ? place.roadAddress : place.address,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(place.category.split('>').last, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}