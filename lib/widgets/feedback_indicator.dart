// lib/widgets/feedback_indicator.dart
import 'package:flutter/material.dart';

class FeedbackIndicator extends StatelessWidget {
  final Map<String, dynamic> calculatedScore;

  const FeedbackIndicator({super.key, required this.calculatedScore});

  @override
  Widget build(BuildContext context) {
    final needsfineScore = calculatedScore['needsfine_score'] ?? 0.0;
    final trustLevel = calculatedScore['trust_level'] ?? 0;
    final authenticity = calculatedScore['authenticity'] ?? false;
    final advertisingWords = calculatedScore['advertising_words'] ?? false;
    final emotionalBalance = calculatedScore['emotional_balance'] ?? false;

    return Column(
      children: [
        // 예상 니즈파인 점수
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                '예상 니즈파인 점수',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '${needsfineScore.toStringAsFixed(1)}점',
                style: const TextStyle(
                  fontSize: 32,
                  color: Color(0xFF9C7CFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(신뢰도: $trustLevel%)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3가지 체크 항목
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildCheckItem(
              label: '정보성',
              isActive: authenticity,
              activeIcon: '👍',
              inactiveIcon: '📝',
            ),
            _buildCheckItem(
              label: '자연스러움',
              isActive: advertisingWords,
              activeIcon: '💜',
              inactiveIcon: '⚠️',
            ),
            _buildCheckItem(
              label: '감정 균형',
              isActive: emotionalBalance,
              activeIcon: '😊',
              inactiveIcon: '😐',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool isActive,
    required String activeIcon,
    required String inactiveIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF9C7CFF) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isActive ? activeIcon : inactiveIcon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF9C7CFF) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
