import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MenuEditor extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const MenuEditor({
    super.key,
    required this.initialItems,
    required this.onChanged,
  });

  @override
  State<MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<MenuEditor> {
  late List<Map<String, dynamic>> _items;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    if (_items.isEmpty) {
      _items.add(_createNewItem()); // Start with one empty item
      // Don't trigger onChanged yet to avoid validation errors immediately
    }
  }

  Map<String, dynamic> _createNewItem() {
    return {'name': '', 'price': '', 'image': null}; // image can be File or String (url)
  }

  void _addItem() {
    setState(() {
      _items.add(_createNewItem());
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) {
        _addItem(); // Keep at least one
      }
    });
    widget.onChanged(_items);
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _items[index]['image'] = File(image.path);
      });
      widget.onChanged(_items);
    }
  }

  void _updateItem(int index, String key, dynamic value) {
    setState(() {
      _items[index][key] = value;
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _items[index];
            final image = item['image']; // Can be File or String(url)

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  // Image
                  GestureDetector(
                    onTap: () => _pickImage(index),
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                        image: image != null 
                          ? DecorationImage(
                              image: image is File ? FileImage(image) : NetworkImage(image) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                      ),
                      child: image == null 
                        ? const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 24)
                        : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Inputs
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: TextEditingController(text: item['name'])
                            ..selection = TextSelection.fromPosition(TextPosition(offset: (item['name'] as String).length)),
                          onChanged: (val) {
                             _items[index]['name'] = val;
                             widget.onChanged(_items);
                          },
                          decoration: const InputDecoration(
                            hintText: '메뉴명',
                            hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(height: 1, color: const Color(0xFFF2F2F7), margin: const EdgeInsets.symmetric(vertical: 4)),
                        TextField(
                          controller: TextEditingController(text: item['price'])
                            ..selection = TextSelection.fromPosition(TextPosition(offset: (item['price'] as String).length)),
                          onChanged: (val) {
                            _items[index]['price'] = val;
                            widget.onChanged(_items);
                          },
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '가격 (원)',
                            hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                        ),
                      ],
                    ),
                  ),
                  // Remove button
                  if (_items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeItem(index),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('메뉴 추가하기'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8A2BE2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF8A2BE2).withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
