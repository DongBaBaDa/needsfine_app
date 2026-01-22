// lib/screens/write_review_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/services/score_calculator.dart';
import 'package:needsfine_app/services/naver_search_service.dart';
import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/models/ranking_models.dart' as model;
import 'package:needsfine_app/widgets/feedback_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:needsfine_app/widgets/notification_badge.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'package:needsfine_app/core/search_trigger.dart';

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

  final List<String> _purposeOptions = ["데이트", "가족 외식", "혼밥", "회식", "힐링", "친구 모임", "기념일"];
  String _selectedPurpose = "";

  final List<String> _priceOptions = ["1만원 이하", "1~3만원", "3~5만원", "5만원 이상"];
  String _selectedPrice = "";

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

      _selectedPlace = NaverPlace(
        title: r.storeName,
        category: '음식점',
        address: r.storeAddress ?? '',
        roadAddress: r.storeAddress ?? '',
      );
      _selectedLat = r.storeLat;
      _selectedLng = r.storeLng;

      // 기존 태그 복원
      for (var tag in r.tags) {
        if (_purposeOptions.contains(tag)) _selectedPurpose = tag;
        if (_priceOptions.contains(tag)) _selectedPrice = tag;
      }

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

  Map<String, dynamic> get _calculatedScore {
    if (_reviewTextController.text.trim().isEmpty || _rating == 0) return {};
    bool hasImages = _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;
    return ScoreCalculator.calculateNeedsFineScore(
      _reviewTextController.text,
      _rating,
      hasImages,
    );
  }

  void _showStoreSearchSheet() {
    if (_isInitialData) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 600,
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
      if (compressedFile != null) setState(() => _newImages.add(compressedFile));
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

      // ✅ 태그 리스트 생성
      List<String> tags = [];
      if (_selectedPurpose.isNotEmpty) tags.add(_selectedPurpose);
      if (_selectedPrice.isNotEmpty) tags.add(_selectedPrice);

      if (_isEditMode) {
        await ReviewService.updateReview(
          reviewId: widget.reviewToEdit!.id,
          content: _reviewTextController.text.trim(),
          rating: _rating,
          photoUrls: finalPhotoUrls,
          tags: tags, // ✅ 태그 전달
        );
      } else {
        AppData().addReview(
          storeName: _selectedPlace!.cleanTitle,
          content: _reviewTextController.text.trim(),
          rating: _rating,
          address: _selectedPlace!.roadAddress.isNotEmpty ? _selectedPlace!.roadAddress : _selectedPlace!.address,
          lat: _selectedLat ?? 0.0,
          lng: _selectedLng ?? 0.0,
          photoUrls: finalPhotoUrls,
          tags: tags, // ✅ 태그 전달
        );

        await ReviewService.createReview(
          storeName: _selectedPlace!.cleanTitle,
          storeAddress: _selectedPlace!.roadAddress.isNotEmpty ? _selectedPlace!.roadAddress : _selectedPlace!.address,
          reviewText: _reviewTextController.text.trim(),
          userRating: _rating,
          photoUrls: finalPhotoUrls,
          lat: _selectedLat,
          lng: _selectedLng,
          tags: tags, // ✅ 태그 전달
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF0E9FF),
      appBar: AppBar(
        title: Text(_isEditMode ? '리뷰 수정' : '리뷰 작성'),
        backgroundColor: const Color(0xFF9C7CFF),
        actions: [
          NotificationBadge(iconColor: Colors.white, onTap: () => Navigator.pushNamed(context, '/notifications')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('방문하신 곳이 맞나요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (_selectedPlace == null)
                GestureDetector(
                  onTap: _showStoreSearchSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.5))),
                    child: Row(
                      children: const [Icon(Icons.search, color: Color(0xFF9C7CFF)), SizedBox(width: 10), Text('가게 이름 검색하기', style: TextStyle(color: Colors.grey, fontSize: 16))],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9C7CFF), width: 1.5)),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0E9FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.store, color: Color(0xFF9C7CFF))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedPlace!.cleanTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(_selectedPlace!.roadAddress.isNotEmpty ? _selectedPlace!.roadAddress : _selectedPlace!.address, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (!_isInitialData)
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() { _selectedPlace = null; _selectedLat = null; _selectedLng = null; }))
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              const Text('리뷰를 작성해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF9C7CFF).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tips_and_updates, color: Color(0xFF9C7CFF), size: 20),
                        SizedBox(width: 8),
                        Text('리뷰 작성 꿀팁!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• 🍽️ 어떤 메뉴가 가장 맛있었나요?', style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
                    const Text('• ✨ 매장 분위기는 어땠나요? (데이트/회식/혼밥 등)', style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
                    const Text('• 😊 직원분들은 친절하셨나요?', style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
                    const Text('• 🚗 주차나 웨이팅 정보도 큰 도움이 돼요!', style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
                    const SizedBox(height: 12),
                    const Text('* 솔직하고 자세한 리뷰는 다른 사용자들에게 큰 도움이 됩니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("방문 목적", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _purposeOptions.map((purpose) {
                    final isSelected = _selectedPurpose == purpose;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(purpose),
                        selected: isSelected,
                        selectedColor: const Color(0xFF9C7CFF),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPurpose = selected ? purpose : "";
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              const Text("1인당 가격대", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _priceOptions.map((price) {
                    final isSelected = _selectedPrice == price;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(price),
                        selected: isSelected,
                        selectedColor: const Color(0xFF9C7CFF),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPrice = selected ? price : "";
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _reviewTextController,
                maxLines: 6,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: '경험을 자유롭게 공유해주세요 (최대 200자)',
                  filled: true, fillColor: Colors.white,
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
                        if (dx < width / 2) setState(() => _rating = starNum - 0.5); else setState(() => _rating = starNum.toDouble());
                      },
                      child: Icon(_rating >= starNum ? Icons.star : (_rating == starNum - 0.5 ? Icons.star_half : Icons.star_border), size: 40, color: _rating >= starNum - 0.5 ? const Color(0xFF9C7CFF) : Colors.grey[300]),
                    );
                  }),
                ),
              ),
              if (_rating > 0) Padding(padding: const EdgeInsets.only(top: 12.0), child: Center(child: Text('선택한 별점: ${_rating.toStringAsFixed(1)}점', style: const TextStyle(fontSize: 18, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)))),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: Text('사진 첨부 (${_newImages.length + _existingImageUrls.length}/5)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF9C7CFF), minimumSize: const Size(double.infinity, 48))
              ),

              if (_existingImageUrls.isNotEmpty || _newImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      ..._existingImageUrls.asMap().entries.map((entry) {
                        return Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(entry.value, width: 80, height: 80, fit: BoxFit.cover)),
                          Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _existingImageUrls.removeAt(entry.key)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                        ]);
                      }),
                      ..._newImages.asMap().entries.map((entry) {
                        return Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover)),
                          Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _newImages.removeAt(entry.key)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                        ]);
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              if (_calculatedScore.isNotEmpty) ...[
                const Text('📊 실시간 분석', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FeedbackIndicator(calculatedScore: _calculatedScore),
                const SizedBox(height: 24)
              ],

              ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C7CFF), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditMode ? '수정 완료' : '리뷰 등록하기')
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
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
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: '가게 이름 입력 (예: 스타벅스)',
                prefixIcon: Icon(Icons.search, color: Color(0xFF9C7CFF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.store_mall_directory, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text("검색 결과가 여기에 표시됩니다.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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