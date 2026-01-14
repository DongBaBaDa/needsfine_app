import 'package:flutter/material.dart';

class StepRegion extends StatelessWidget {
  final String? selectedSido;
  final String? selectedSigungu;
  final List<String> sidoList;
  final List<String> sigunguList;
  final Function(String?) onSidoChanged;
  final Function(String?) onSigunguChanged;

  const StepRegion({
    super.key,
    required this.selectedSido,
    required this.selectedSigungu,
    required this.sidoList,
    required this.sigunguList,
    required this.onSidoChanged,
    required this.onSigunguChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}
