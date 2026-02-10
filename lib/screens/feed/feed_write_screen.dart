import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:needsfine_app/services/feed_service.dart';
import 'package:needsfine_app/services/naver_search_service.dart';
import 'package:needsfine_app/services/naver_map_service.dart';
import 'package:needsfine_app/core/search_trigger.dart';
import 'package:needsfine_app/core/profanity_filter.dart';

// ✅ FIX: AppLocalizations import 누락으로 타입/참조 에러가 났던 부분
import 'package:needsfine_app/l10n/app_localizations.dart';

class FeedWriteScreen extends StatefulWidget {
  final Map<String, dynamic>? post; // Optional post for editing
  const FeedWriteScreen({super.key, this.post});

  @override
  State<FeedWriteScreen> createState() => _FeedWriteScreenState();
}

class _FeedWriteScreenState extends State<FeedWriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _contentController = TextEditingController();
  List<TextEditingController> _voteOptionsControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final NaverSearchService _naverSearchService = NaverSearchService();
  final NaverGeocodingService _geocodingService = NaverGeocodingService();

  NaverPlace? _selectedPlace; // Only if new/changed, or constructed from existing data
  String? _selectedRegion;
  double? _lat;
  double? _lng;

  // Image handling
  List<String> _existingImages = [];
  List<File> _newImages = [];
  bool _isSubmitting = false;

  static const Color _brand = Color(0xFFC87CFF);
  static const Color _bg = Color(0xFFF2F2F7);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check for Edit Mode
    if (widget.post != null) {
      _initEditMode();
    }

    _tabController.addListener(() => setState(() {}));
  }

  void _initEditMode() {
    final post = widget.post!;
    _contentController.text = post['content'] ?? '';

    // Type
    String type = post['post_type'] ?? 'recommendation';
    int index = ['recommendation', 'question', 'vote'].indexOf(type);
    if (index != -1) _tabController.index = index;

    // Store logic (Reconstruct basic info)
    if (post['store_name'] != null) {
      _selectedPlace = NaverPlace(
        title: post['store_name'],
        category: '', // Basic reconstruction
        roadAddress: post['region'] ?? '',
        address: '',
      ); // Minimal reconstruction
    }
    _selectedRegion = post['region'];
    // Recover coordinates if available (check if post map has them, usually from DB select *)
    if (post['lat'] != null) _lat = (post['lat'] as num).toDouble();
    if (post['lng'] != null) _lng = (post['lng'] as num).toDouble();

    // Vote Options
    if (type == 'vote' && post['vote_options'] != null) {
      List<dynamic> options = post['vote_options'];
      _voteOptionsControllers = options.map((e) => TextEditingController(text: e.toString())).toList();
      // Ensure at least 2
      while (_voteOptionsControllers.length < 2) {
        _voteOptionsControllers.add(TextEditingController());
      }
    }

    // Images
    if (post['image_urls'] != null) {
      _existingImages = List<String>.from(post['image_urls']);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    for (var c in _voteOptionsControllers) c.dispose();
    super.dispose();
  }

  // --- Actions ---

  void _addVoteOption() {
    if (_voteOptionsControllers.length < 4) {
      setState(() {
        _voteOptionsControllers.add(TextEditingController());
      });
    }
  }

  Future<void> _pickImage() async {
    int totalImages = _existingImages.length + _newImages.length;
    if (totalImages >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 5장까지 첨부 가능합니다')));
      return;
    }
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      for (var image in images) {
        if (_existingImages.length + _newImages.length >= 5) break;
        File? compressedFile = await _compressImage(File(image.path));
        if (compressedFile != null) {
          setState(() => _newImages.add(compressedFile));
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

  void _showStoreSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StoreSearchSheet(
        searchService: _naverSearchService,
        onPlaceSelected: (place) async {
          setState(() {
            _selectedPlace = place;
          });
          Navigator.pop(context);
          
          // Fetch Coordinates
          try {
             final response = await _geocodingService.searchAddress(place.roadAddress);
             if (response.addresses.isNotEmpty) {
               setState(() {
                 _lng = double.tryParse(response.addresses.first.x);
                 _lat = double.tryParse(response.addresses.first.y);
               });
             }
          } catch (e) {
             debugPrint("Geocoding failed: $e");
          }
        },
      ),
    );
  }

  Future<void> _submitPost() async {
    final String content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요')));
      return;
    }

    // Validation based on type
    final index = _tabController.index;
    if (index == 0 && _selectedPlace == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('맛집을 추천하려면 가게를 선택해주세요')));
       return;
    }
    if (index == 2) {
       if (_voteOptionsControllers.any((c) => c.text.trim().isEmpty)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('빈 투표 항목이 있습니다')));
         return;
       }
    }

    if (ProfanityFilter.hasProfanity(content)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('부적절한 단어가 포함되어 있습니다')));
       return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload New Images
      final uploadedUrls = <String>[];
      if (_newImages.isNotEmpty) {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id ?? 'anon';
        for (final image in _newImages) {
          final fileName = '${const Uuid().v4()}.jpg';
          final filePath = 'feed/$userId/$fileName';
          await supabase.storage.from('review_photos').upload(filePath, image, fileOptions: const FileOptions(contentType: 'image/jpeg'));
          uploadedUrls.add(supabase.storage.from('review_photos').getPublicUrl(filePath));
        }
      }

      // Combine Existing + New
      final finalImageUrls = [..._existingImages, ...uploadedUrls];

      // 2. Prepare Data
      String type = ['recommendation', 'question', 'vote'][index];
      List<String>? voteOptions;
      if (type == 'vote') {
        voteOptions = _voteOptionsControllers.map((c) => c.text.trim()).toList();
      }

      // 3. Create or Update
      if (widget.post == null) {
        // Create
        await FeedService.createPost(
          type: type,
          content: content,
          imageUrls: finalImageUrls,
          storeName: _selectedPlace?.cleanTitle,
          region: _selectedRegion ?? (_selectedPlace?.roadAddress),
          voteOptions: voteOptions,
          lat: _lat,
          lng: _lng,
        );
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 등록되었습니다!')));
      } else {
        // Update
        await FeedService.updatePost(
          postId: widget.post!['id'],
          content: content,
          imageUrls: finalImageUrls,
          storeName: _selectedPlace?.cleanTitle,
          region: _selectedRegion ?? (_selectedPlace?.roadAddress), // Keep existing region logic or update?
          voteOptions: voteOptions,
          lat: _lat,
          lng: _lng,
        );
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 수정되었습니다!')));
      }

      Navigator.pop(context, true); // Return true to refresh list

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Builders ---
  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.post != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(isEdit ? l10n.editPost : l10n.newPost, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: isEdit
          ? null // Hide TabBar in Edit Mode (Type change usually not allowed or complicated, simplicity first)
          : TabBar(
          controller: _tabController,
          labelColor: _brand,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _brand,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: [
             Tab(text: l10n.tabStore),
             Tab(text: l10n.tabQuestion),
             Tab(text: l10n.tabVote),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Dynamic Form based on Tab
            if (_tabController.index == 0) _buildStoreSelector(l10n),
            if (_tabController.index == 1) _buildRegionSelector(),

            const SizedBox(height: 24),

            // Content Input
             Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _contentController,
                  maxLines: 6,
                   maxLength: 300,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0 ? l10n.hintReview
                            : _tabController.index == 1 ? l10n.hintQuestion
                            : l10n.hintVote,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
             ),

             if (_tabController.index == 2) ...[
               const SizedBox(height: 24),
               _buildVoteOptionsList(l10n),
             ],

             const SizedBox(height: 24),

             _buildImageArea(),

             const SizedBox(height: 32),
             _buildGuidelines(),
             const SizedBox(height: 24),

             ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
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
                    : Text(isEdit ? l10n.editAction : l10n.postAction)
            ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ... (Guidelines omitted for brevity, logic remains same)
  Widget _buildGuidelines() {
     final l10n = AppLocalizations.of(context)!;
     // ... Reuse existing code ...
     return Container(
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
              Text(l10n.cgTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem(l10n.cgItem1Title, l10n.cgItem1Desc),
          const SizedBox(height: 8),
          _buildGuidelineItem(l10n.cgItem2Title, l10n.cgItem2Desc),
          const SizedBox(height: 8),
          _buildGuidelineItem(l10n.cgItem3Title, l10n.cgItem3Desc),
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

  Widget _buildStoreSelector(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _showStoreSearchSheet,
      child: Container(
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
              child: _selectedPlace == null
                  ? Text(l10n.selectStoreHint, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedPlace!.cleanTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(_selectedPlace!.roadAddress, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
            ),
            if (_selectedPlace != null)
              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedPlace = null))
            else
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionSelector() {
     return Container(height: 0);
  }

  Widget _buildVoteOptionsList(AppLocalizations l10n) {
    bool isEdit = widget.post != null;
    return Column(
      children: [
        ..._voteOptionsControllers.asMap().entries.map((entry) {
          int idx = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isEdit ? Colors.grey[100] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: entry.value,
                enabled: !isEdit, // Disable editing if edit mode
                style: TextStyle(color: isEdit ? Colors.grey[600] : Colors.black),
                decoration: InputDecoration(
                  hintText: "${l10n.voteOption} ${idx + 1}",
                  border: InputBorder.none,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                ),
              ),
            ),
          );
        }),
        if (!isEdit && _voteOptionsControllers.length < 4) // Hide add button if edit
          TextButton.icon(
             onPressed: _addVoteOption,
             icon: const Icon(Icons.add_circle_outline, color: _brand),
             label: Text(l10n.addOption, style: const TextStyle(color: _brand, fontWeight: FontWeight.bold)),
          ),
        if (isEdit)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(l10n.voteEditWarning, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildImageArea() {
    return SizedBox(
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
                  const Icon(Icons.add_a_photo_rounded, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text("${_existingImages.length + _newImages.length}/5", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Existing Images
          ..._existingImages.asMap().entries.map((entry) => Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(entry.value, fit: BoxFit.cover, height: 100),
                ),
              ),
              Positioned(
                top: 4, right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _existingImages.removeAt(entry.key)),
                  child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
                ),
              ),
            ],
          )),
          // New Images
          ..._newImages.asMap().entries.map((entry) => Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(entry.value, fit: BoxFit.cover, height: 100),
                ),
              ),
              Positioned(
                top: 4, right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _newImages.removeAt(entry.key)),
                  child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

// Reuse similar Search Sheet from WriteReviewScreen or make a shared widget
class _StoreSearchSheet extends StatefulWidget {
  final NaverSearchService searchService;
  final Function(NaverPlace) onPlaceSelected;
  const _StoreSearchSheet({required this.searchService, required this.onPlaceSelected});

  @override
  State<_StoreSearchSheet> createState() => _StoreSearchSheetState();
}

class _StoreSearchSheetState extends State<_StoreSearchSheet> {
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
       setState(() => _isLoading = true);
       try {
         final res = await widget.searchService.searchPlaces(query);
         if (mounted) setState(() => _results = res ?? []);
       } finally {
         if (mounted) setState(() => _isLoading = false);
       }
     });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchStoreName,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _results[index];
                return ListTile(
                  title: Text(place.cleanTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(place.roadAddress, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  onTap: () => widget.onPlaceSelected(place),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
