import 'package:flutter/material.dart';

class TasteSelectionScreen extends StatefulWidget {
  const TasteSelectionScreen({super.key});

  @override
  State<TasteSelectionScreen> createState() => _TasteSelectionScreenState();
}

class _TasteSelectionScreenState extends State<TasteSelectionScreen> {
  final List<String> _foodCategories = ['한식', '중식', '일식', '양식', '분식', '아시안', '패스트푸드', '카페/디저트', '술집'];
  final List<String> _atmosphereCategories = ['조용한', '활기찬', '분위기 좋은', '뷰가 좋은', '가성비', '고급스러운', '혼밥하기 좋은', '단체모임'];
  
  final Set<String> _selectedTastes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 취향 선택'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedTastes.toList());
            },
            child: const Text("저장", style: TextStyle(color: Colors.black, fontSize: 16)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("어떤 음식을 좋아하세요?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("선택해주시면 딱 맞는 맛집을 추천해드려요.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _foodCategories.map((food) => _buildChip(food)).toList(),
          ),
          const SizedBox(height: 40),
          const Text("어떤 분위기를 선호하세요?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _atmosphereCategories.map((mood) => _buildChip(mood)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSelected = _selectedTastes.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedTastes.add(label);
          } else {
            _selectedTastes.remove(label);
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.deepOrange.withOpacity(0.1),
      checkmarkColor: Colors.deepOrange,
      side: BorderSide(color: isSelected ? Colors.deepOrange : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepOrange : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
