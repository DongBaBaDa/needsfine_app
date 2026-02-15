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
import 'package:needsfine_app/services/naver_search_service.dart';
import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/models/ranking_models.dart' as model;
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';
import 'package:needsfine_app/core/profanity_filter.dart'; // Correct path
import 'package:needsfine_app/core/search_trigger.dart'; // searchTrigger & SearchTarget
import 'package:needsfine_app/widgets/store_search_sheet.dart'; // ✅ StoreSearchSheet 추가

// ... (imports remain)

class WriteReviewScreen extends StatefulWidget {
  final model.Review? reviewToEdit;
  final String? initialStoreName;
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const WriteReviewScreen({
    super.key, 
    this.reviewToEdit,
    this.initialStoreName,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
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

  // ✅ 태그 데이터 (Localized Getter)
  Map<String, List<String>> _getTagCategories(AppLocalizations l10n) {
    return {
      l10n.visitPurposeSolo: [
        l10n.tagSoloEating, l10n.tagHealing, l10n.tagCostEffective, l10n.tagBrunch, 
        l10n.tagTakeout, l10n.tagDelivery, l10n.tagQuiet, l10n.tagSimple
      ],
      l10n.visitPurposeCouple: [
        l10n.tagDate, l10n.tagAnniversary, l10n.tagAtmosphere, l10n.tagView, 
        l10n.tagExotic, l10n.tagWine, l10n.tagCourse, l10n.tagDelivery
      ],
      l10n.visitPurposeGroup: [
        l10n.tagCompanyDinner, l10n.tagFamily, l10n.tagFriends, l10n.tagParking, 
        l10n.tagPrivateRoom, l10n.tagConversation, l10n.tagSpacious, l10n.tagDelivery
      ],
    };
  }

  // ✅ 현재 선택된 태그 카테고리 인덱스
  int _currentTabIndex = 0;
  final Set<String> _selectedTags = {};

  // ✅ 실시간 분석 상태
  double _predictedScore = 0.0;
  int _predictedTrust = 0;
  String _feedbackMessage = "";
  bool _isFeedbackWarning = false;
  bool _showAnalysis = false;
  Timer? _debounce;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_feedbackMessage.isEmpty) {
      _feedbackMessage = AppLocalizations.of(context)!.mostMemorableTaste;
    }
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  // ✅ [수정됨] 실시간 분석 및 피드백 생성 (Server-Side Debounce)
  void _analyzeRealTime() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final text = _reviewTextController.text.trim();
    if (text.isEmpty) {
      if (mounted) setState(() => _showAnalysis = false);
      return;
    }

    // ⚡ 200ms Debounce: 더 빠른 반응 속도
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      bool hasImages = _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;
      double inputRating = _rating == 0 ? 3.0 : _rating;

      if (mounted) setState(() => _showAnalysis = true); // 분석 중 표시 (Optional: Loading indicator)

      try {
        final result = await ReviewService.analyzeReview(
          text: text,
          userRating: inputRating,
          hasPhoto: hasImages,
          tags: _selectedTags.toList(), // ✅ 선택된 태그 전달 (배달 등 확인용)
        );

        if (mounted) {
          setState(() {
            _predictedScore = result['needsfine_score'];
            _predictedTrust = result['trust_level'];
            _feedbackMessage = result['message'];
            _isFeedbackWarning = result['is_warning'];
            _showAnalysis = true;
          });
        }
      } catch (e) {
        debugPrint("분석 요청 실패: $e");
      }
    });
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
                child: StoreSearchSheet(
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
    final currentCount = _newImages.length + _existingImageUrls.length;
    if (currentCount >= 10) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("최대 10장까지만 업로드 가능합니다.")));
      return;
    }

    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
      maxWidth: 1024,
      imageQuality: 80,
    );
    
    // ignore: unnecessary_null_comparison
    if (pickedFiles == null || pickedFiles.isEmpty) return;

    final availableSlots = 10 - currentCount;
    final filesToAdd = pickedFiles.take(availableSlots).map((x) => File(x.path)).toList();

    setState(() {
      _newImages.addAll(filesToAdd);
    });

    if (pickedFiles.length > availableSlots) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("최대 10장까지만 업로드 가능합니다.")));
    }

    _analyzeRealTime();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.selectStore)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.selectRating)));
      return;
    }

    if (ProfanityFilter.hasProfanity(_reviewTextController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profanityError), backgroundColor: Colors.red),
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
            content: Text(_isEditMode ? AppLocalizations.of(context)!.reviewUpdated : AppLocalizations.of(context)!.reviewSubmitted),
            backgroundColor: const Color(0xFF9C7CFF)
        ),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.processFailed(e.toString()))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ✅ [수정] 태그 카테고리 탭 UI (횡스크롤)
  Widget _buildCategoryTabs() {
    final l10n = AppLocalizations.of(context)!;
    final categories = _getTagCategories(l10n);
    
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories.keys.elementAt(index);
          final isSelected = _currentTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _currentTabIndex = index),
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
    final l10n = AppLocalizations.of(context)!;
    final tags = _getTagCategories(l10n).values.elementAt(_currentTabIndex);
    
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
          _isEditMode ? AppLocalizations.of(context)!.editReviewTitle : AppLocalizations.of(context)!.writeReviewTitle,
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
                        Text(AppLocalizations.of(context)!.findStoreTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.findStoreSubtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                    Text(AppLocalizations.of(context)!.ratingTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          '${_rating.toStringAsFixed(1)}${AppLocalizations.of(context)!.points}',
                          style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ✅ 3. 방문 목적 태그 (수정됨: 횡스크롤 탭 + 횡스크롤 태그)
              Text(AppLocalizations.of(context)!.featureTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              hintText: AppLocalizations.of(context)!.reviewHint,
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            onChanged: (_) => _analyzeRealTime(),
                            validator: (value) => (value == null || value.trim().isEmpty) ? AppLocalizations.of(context)!.suggestionHint : null,
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
                                    _buildScoreMetric(AppLocalizations.of(context)!.predictedNeedsFineScore, _predictedScore.toStringAsFixed(1), true),
                                    Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
                                    _buildScoreMetric(AppLocalizations.of(context)!.reliability, "$_predictedTrust%", false),
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
                                        // Icon removed as per user request
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Message
                                              Text(
                                                _feedbackMessage,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.3,
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
                            Text("${_newImages.length + _existingImageUrls.length}/10", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    ..._existingImageUrls.asMap().entries.map((entry) => _buildPhotoItem(entry.value, true, entry.key)),
                    ..._newImages.asMap().entries.map((entry) => _buildPhotoItem(entry.value, false, entry.key)),
                  ],
                ),
              ),

              _buildGuidelines(),
              
              const SizedBox(height: 24),

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
                      : Text(_isEditMode ? AppLocalizations.of(context)!.editReviewComplete : AppLocalizations.of(context)!.submitReviewTitle)
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelines() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(l10n.guideTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem(l10n.guide1Title, l10n.guide1Desc),
          const SizedBox(height: 8),
          _buildGuidelineItem(l10n.guide2Title, l10n.guide2Desc), 
          const SizedBox(height: 8),
          _buildGuidelineItem(l10n.guide3Title, l10n.guide3Desc),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("• $title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[800])),
        const SizedBox(height: 2),
        Text(content, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4)),
      ],
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

