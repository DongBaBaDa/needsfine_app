import 'package:flutter/material.dart';

class StepGender extends StatelessWidget {
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const StepGender({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSelectionCard(context, '남성', 'male', Icons.man),
        const SizedBox(height: 12),
        _buildSelectionCard(context, '여성', 'female', Icons.woman),
      ],
    );
  }

  Widget _buildSelectionCard(BuildContext context, String label, String value, IconData icon) {
    bool isSelected = selectedGender == value;
    return GestureDetector(
      onTap: () => onGenderSelected(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C7CFF).withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF9C7CFF) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? const Color(0xFF9C7CFF) : Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF9C7CFF) : Colors.black)),
          ],
        ),
      ),
    );
  }
}
