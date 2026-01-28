import 'package:flutter/material.dart';

class StepRegion extends StatelessWidget {
  final String? selectedSido;
  final String? selectedSigungu;
  final List<String> sidoList;
  final List<String> sigunguList;
  final ValueChanged<String?> onSidoChanged;
  final ValueChanged<String?> onSigunguChanged;
  final VoidCallback onNext; // [NEW] 부모에서 넘겨주는 다음 페이지 이동 함수

  const StepRegion({
    super.key,
    required this.selectedSido,
    required this.selectedSigungu,
    required this.sidoList,
    required this.sigunguList,
    required this.onSidoChanged,
    required this.onSigunguChanged,
    required this.onNext, // [NEW]
  });

  @override
  Widget build(BuildContext context) {
    // 시/도, 시/군/구 모두 선택되어야 버튼 활성화
    final isEnabled = selectedSido != null && selectedSigungu != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('어디에 거주하시나요?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('동네 맛집 추천을 위해 필요해요.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 40),

          DropdownButtonFormField<String>(
            value: selectedSido,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '시/도'),
            items: sidoList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onSidoChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedSigungu,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '시/군/구'),
            items: sigunguList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: selectedSido == null ? null : onSigunguChanged,
          ),

          const Spacer(),

          // [NEW] 다음 버튼 추가
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isEnabled ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}