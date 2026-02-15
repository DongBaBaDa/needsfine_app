import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:needsfine_app/widgets/store_registration/operating_hours_selector.dart';
import 'package:needsfine_app/widgets/store_registration/menu_editor.dart';

class StoreEditScreen extends StatefulWidget {
  final Map<String, dynamic> storeData;

  const StoreEditScreen({super.key, required this.storeData});

  @override
  State<StoreEditScreen> createState() => _StoreEditScreenState();
}

class _StoreEditScreenState extends State<StoreEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _introController;

  // State Variables
  List<String> _existingImages = [];
  List<File> _newImages = [];
  List<String> _deletedImages = [];
  
  List<Map<String, dynamic>> _menuItems = [];
  Map<String, dynamic> _operatingHours = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final data = widget.storeData;

    _nameController = TextEditingController(text: data['name']);
    _addressController = TextEditingController(text: data['address']);
    _phoneController = TextEditingController(text: data['phone_number']);
    _introController = TextEditingController(text: data['description']);

    // Images
    if (data['images'] != null) {
      _existingImages = List<String>.from(data['images']);
    } else if (data['photos'] != null) { // Fallback for old schema if any
      _existingImages = List<String>.from(data['photos']);
    }

    // Menu
    if (data['menu'] is List) {
      _menuItems = List<Map<String, dynamic>>.from(data['menu']);
    }

    // Hours
    if (data['business_hours_data'] is Map) {
      _operatingHours = Map<String, dynamic>.from(data['business_hours_data']);
    } else if (data['hours'] is Map) { // Fallback
      _operatingHours = Map<String, dynamic>.from(data['hours']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    int currentCount = _existingImages.length + _newImages.length;
    
    if (currentCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 10장까지 등록 가능합니다.')));
      return;
    }

    final List<XFile> images = await picker.pickMultiImage(limit: 10 - currentCount);
    
    if (images.isNotEmpty) {
      for (var img in images) {
        File? compressed = await _compressImage(File(img.path));
        if (compressed != null) {
          setState(() => _newImages.add(compressed));
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

  void _removeExistingImage(int index) {
    setState(() {
      _deletedImages.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final storeId = widget.storeData['id'];
      final user = _supabase.auth.currentUser;

      // 1. Upload New Images
      List<String> newImageUrls = [];
      if (user != null) {
        for (var file in _newImages) {
          final fileName = '${const Uuid().v4()}.jpg';
          final filePath = 'store_$storeId/$fileName'; // Organized by store ID
          await _supabase.storage.from('store-photos').upload(filePath, file); // Assuming store-photos bucket
          final url = _supabase.storage.from('store-photos').getPublicUrl(filePath);
          newImageUrls.add(url);
        }
      }

      // Combine existing and new
      final finalImages = [..._existingImages, ...newImageUrls];

      // 2. Upload Menu Images (if any new files)
      List<Map<String, dynamic>> finalMenu = [];
      for (var item in _menuItems) {
        String? menuImageUrl;
        if (item['image'] != null && item['image'] is File) {
           final fileName = 'menu_${const Uuid().v4()}.jpg';
           final filePath = 'store_$storeId/$fileName';
           await _supabase.storage.from('store-photos').upload(filePath, item['image']);
           menuImageUrl = _supabase.storage.from('store-photos').getPublicUrl(filePath);
        } else if (item['image'] is String) {
           menuImageUrl = item['image'];
        }

        finalMenu.add({
          'name': item['name'],
          'price': item['price'],
          'photo_url': menuImageUrl,
        });
      }

      // 3. Update Database
      final updates = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone_number': _phoneController.text,
        'description': _introController.text,
        'images': finalImages,
        'menu': finalMenu,
        'business_hours_data': _operatingHours,
      };

      await _supabase.from('stores').update(updates).eq('id', storeId);

      // Optional: Log edit history
      if (user != null) {
        await _supabase.from('store_edits').insert({
          'store_id': storeId,
          'user_id': user.id,
          'field_name': 'full_update',
          'old_value': null, // Too complex to diff efficiently here
          'new_value': null,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('매장 정보가 수정되었습니다 ✅')));
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }

    } catch (e) {
      debugPrint("매장 수정 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 실패: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('매장 정보 수정', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 18)),
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveStore,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8A2BE2))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
              _buildSectionHeader('기본 정보'),
              _buildCard(
                children: [
                  _buildTextField(_nameController, '매장명', Icons.store),
                  const SizedBox(height: 16),
                  _buildTextField(_addressController, '주소', Icons.location_on_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, '연락처', Icons.phone_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_introController, '소개/설명', Icons.description_outlined, maxLines: 3),
                ],
              ),
              const SizedBox(height: 24),

              // Photos
              _buildSectionHeader('매장 사진 (최대 10장)'),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 1 + _existingImages.length + _newImages.length,
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
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFFF2F2F7), shape: BoxShape.circle),
                                child: Icon(Icons.add_a_photo_rounded, color: Colors.grey[500], size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text('${_existingImages.length + _newImages.length}/10', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }

                    int adjustedIndex = index - 1;
                    bool isExisting = adjustedIndex < _existingImages.length;
                    
                    Widget imageWidget;
                    if (isExisting) {
                      imageWidget = Image.network(_existingImages[adjustedIndex], width: 120, height: 120, fit: BoxFit.cover);
                    } else {
                      imageWidget = Image.file(_newImages[adjustedIndex - _existingImages.length], width: 120, height: 120, fit: BoxFit.cover);
                    }

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageWidget,
                        ),
                        Positioned(
                          top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () {
                              if (isExisting) {
                                _removeExistingImage(adjustedIndex);
                              } else {
                                _removeNewImage(adjustedIndex - _existingImages.length);
                              }
                            },
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
              const SizedBox(height: 24),

              // Hours
              _buildSectionHeader('영업 시간'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(20),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: OperatingHoursSelector(
                  initialValue: _operatingHours,
                  onChanged: (val) => _operatingHours = val,
                ),
              ),
              const SizedBox(height: 24),

              // Menu
              _buildSectionHeader('대표 메뉴'),
              MenuEditor(
                initialItems: _menuItems,
                onChanged: (val) => _menuItems = val,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D2D3A))),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
          child: Icon(icon, color: Colors.grey[400], size: 22),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            decoration: InputDecoration(
              hintText: label,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
