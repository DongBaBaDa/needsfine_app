import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/widgets/store_search_sheet.dart';
import 'package:needsfine_app/services/naver_search_service.dart';
import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:needsfine_app/widgets/store_registration/operating_hours_selector.dart';
import 'package:needsfine_app/widgets/store_registration/menu_editor.dart';

class RequestStoreRegistrationScreen extends StatefulWidget {
  const RequestStoreRegistrationScreen({super.key});

  @override
  State<RequestStoreRegistrationScreen> createState() => _RequestStoreRegistrationScreenState();
}

class _RequestStoreRegistrationScreenState extends State<RequestStoreRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  // Services
  final NaverSearchService _naverSearchService = NaverSearchService();
  final NaverGeocodingService _geocodingService = NaverGeocodingService();

  // Controllers
  final _introController = TextEditingController();
  final _phoneController = TextEditingController(); // Auto-filled from search if available

  // State Variables
  NaverPlace? _selectedPlace;
  double? _selectedLat;
  double? _selectedLng;
  
  // Enhanced Data Structures
  List<File> _storeImages = []; // Up to 10 images
  List<Map<String, dynamic>> _menuItemsNew = []; // Structured menu
  Map<String, dynamic> _operatingHours = {}; // Structured hours
  
  bool _isLoading = false;

  @override
  void dispose() {
    _introController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- Actions ---

  void _showStoreSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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

                  // Ensure we are still mounted before using context
                  if (!mounted) return;
                  
                  try {
                    setState(() {
                      _selectedPlace = place;
                      _selectedLat = lat;
                      _selectedLng = lng;
                    });
                    
                    // Check if we can pop before popping to avoid exceptions
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    debugPrint("Error closing search sheet: $e");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    // Limit to 10 total
    if (_storeImages.length >= 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 10장까지 등록 가능합니다.')));
      return;
    }

    final List<XFile> images = await picker.pickMultiImage(limit: 10 - _storeImages.length);
    
    if (images.isNotEmpty) {
      for (var img in images) {
        File? compressed = await _compressImage(File(img.path));
        if (compressed != null) {
          setState(() => _storeImages.add(compressed));
        }
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





  // --- Submit ---

  Future<void> _submitRequest() async {
    if (_selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.selectStoreHint)));
      return;
    }
    // Validation: Require at least one photo? User didn't specify, but good practice.
    // Let's make essential fields required.
    if (_introController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('매장 소개를 입력해주세요.')));
        return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Upload Store Images
      List<String> imageUrls = [];
      for (var file in _storeImages) {
        final fileName = '${const Uuid().v4()}.jpg';
        final filePath = '${user.id}/$fileName';
        await _supabase.storage.from('review_photos').upload('requests/$filePath', file);
        final url = _supabase.storage.from('review_photos').getPublicUrl('requests/$filePath');
        imageUrls.add(url);
      }

      // 2. Upload Menu Images and Prepare Menu Data
      List<Map<String, dynamic>> finalMenu = [];
      for (var item in _menuItemsNew) {
        String? menuImageUrl;
        if (item['image'] != null && item['image'] is File) {
           final fileName = 'menu_${const Uuid().v4()}.jpg';
           final filePath = '${user.id}/$fileName';
           await _supabase.storage.from('review_photos').upload('requests/$filePath', item['image']);
           menuImageUrl = _supabase.storage.from('review_photos').getPublicUrl('requests/$filePath');
        } else if (item['image'] is String) {
           menuImageUrl = item['image'];
        }

        finalMenu.add({
          'name': item['name'],
          'price': item['price'],
          'photo_url': menuImageUrl,
        });
      }

      // 3. Insert Data
      await _supabase.from('store_registration_requests').insert({
        'user_id': user.id,
        'store_name': _selectedPlace!.cleanTitle,
        'store_road_address': _selectedPlace!.roadAddress,
        'store_address': _selectedPlace!.address.isNotEmpty ? _selectedPlace!.address : _selectedPlace!.roadAddress,
        'store_lat': _selectedLat,
        'store_lng': _selectedLng,
        'store_intro': _introController.text,
        'store_phone': _phoneController.text,
        // Use new columns
        'store_images': imageUrls, 
        'store_menu_new': finalMenu,
        'store_hours_new': _operatingHours,
        // Keep legacy columns for compatibility if needed, or null
        'store_photo_url': imageUrls.isNotEmpty ? imageUrls.first : null,
        'store_hours': _operatingHours['open'] != null ? "${_operatingHours['open']}~${_operatingHours['close']}" : null,
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.requestSuccess)),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Builder ---

  // --- UI Builder ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Light grey background
      appBar: AppBar(
        title: Text(l10n.requestStoreRegistration, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 18)),
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 매장 검색 섹션 (가장 중요)
              _buildSectionHeader(l10n.storeName, isEssential: true),
              GestureDetector(
                onTap: _showStoreSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A2BE2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_rounded, color: Color(0xFF8A2BE2), size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPlace?.cleanTitle ?? l10n.searchStoreName,
                              style: TextStyle(
                                color: _selectedPlace == null ? Colors.grey[400] : Colors.black,
                                fontSize: 16,
                                fontWeight: _selectedPlace == null ? FontWeight.w500 : FontWeight.w700,
                              ),
                            ),
                            if (_selectedPlace != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedPlace!.roadAddress.isNotEmpty ? _selectedPlace!.roadAddress : _selectedPlace!.address,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. 상세 정보 입력 섹션 (카드 형태)
              _buildSectionHeader(l10n.storeIntro),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _introController,
                      hint: l10n.storeIntro,
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      hint: l10n.storePhone,
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. 영업 시간
              // 3. 영업 시간 (상세)
              _buildSectionHeader(l10n.storeHours),
              Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(20),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                 ),
                 child: OperatingHoursSelector(
                   initialValue: _operatingHours,
                   onChanged: (val) {
                     _operatingHours = val;
                   },
                 ),
              ),
              const SizedBox(height: 30),

              // 4. 대표 메뉴 (상세: 이름/가격/사진)
              _buildSectionHeader(l10n.storeMenu),
              MenuEditor(
                initialItems: _menuItemsNew,
                onChanged: (val) {
                  _menuItemsNew = val;
                },
              ),
              const SizedBox(height: 30),

              // 5. 대표 사진 (최대 10장)
              _buildSectionHeader('${l10n.storePhoto} (최대 10장)'), 
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _storeImages.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                       return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), shape: BoxShape.circle),
                                child: Icon(Icons.add_a_photo_rounded, color: Colors.grey[500], size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text('${_storeImages.length}/10', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }
                    final image = _storeImages[index - 1];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(image, width: 120, height: 120, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _storeImages.removeAt(index - 1)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 50),

              // 제출 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shadowColor: const Color(0xFF8A2BE2).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(l10n.submitRequest, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isEssential = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D2D3A))),
          if (isEssential)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text("*", style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
          child: Icon(icon, color: Colors.grey[400], size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            cursorColor: const Color(0xFF8A2BE2),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }


}
