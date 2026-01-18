import 'package:flutter/material.dart';

class FeedbackIndicator extends StatelessWidget {
  final Map<String, dynamic> calculatedScore;

  const FeedbackIndicator({super.key, required this.calculatedScore});

  @override
  Widget build(BuildContext context) {
    if (calculatedScore.isEmpty) return const SizedBox.shrink();

    // 데이터 추출
    final double score = calculatedScore['needsfine_score'] ?? 0.0;
    final int trustLevel = calculatedScore['trust_level'] ?? 0;
    final List<String> tags = List<String>.from(calculatedScore['tags'] ?? []);

    // 신뢰도 색상
    Color trustColor;
    if (trustLevel >= 80) trustColor = Colors.green;
    else if (trustLevel >= 50) trustColor = Colors.orange;
    else trustColor = Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 예상 점수
              Column(
                children: [
                  const Text('예상 니즈파인 점수', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C7CFF),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              // 신뢰도
              Column(
                children: [
                  const Text('리뷰 신뢰도', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.verified_user, size: 20, color: trustColor),
                      const SizedBox(width: 4),
                      Text(
                        '$trustLevel%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: trustColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 추출 태그 표시
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E9FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF9C7CFF).withOpacity(0.5)),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Color(0xFF6200EE),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),

          if (tags.isEmpty)
            const Text(
              "작성된 내용에서 키워드를 분석 중입니다...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

          const SizedBox(height: 8),
          // 팁 제공
          if (trustLevel < 50)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(
                    "구체적인 경험(메뉴, 분위기)을 추가해보세요!",
                    style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}