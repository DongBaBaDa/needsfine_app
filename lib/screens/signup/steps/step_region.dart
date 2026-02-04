import 'package:flutter/material.dart';

import 'package:needsfine_app/l10n/app_localizations.dart';

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
          Text(AppLocalizations.of(context)!.whereDoYouLive, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.regionInfo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 40),

          DropdownButtonFormField<String>(
            value: selectedSido,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: AppLocalizations.of(context)!.city),
            items: sidoList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onSidoChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedSigungu,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: AppLocalizations.of(context)!.district),
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
              child: Text(AppLocalizations.of(context)!.next, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}