import 'package:flutter/material.dart';

// Const Colors defined in requirements
const Color kNeedsFinePurple = Color(0xFFC87CFF);
const Color kBackground = Color(0xFFFFFDF9);

/// Task 2: Store Insight Banner
/// 가게의 특징을 단점에서 장점으로 승화시킨 문구를 보여주는 배너
class StoreInsightBanner extends StatelessWidget {
  final String keyword;
  final String description;

  const StoreInsightBanner({
    super.key,
    required this.keyword,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // 배경: 브랜드 컬러 Opacity 0.05
        color: kNeedsFinePurple.withOpacity(0.05),
        // 테두리: 브랜드 컬러 Opacity 0.2
        border: Border.all(
          color: kNeedsFinePurple.withOpacity(0.2),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0, right: 12.0),
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: kNeedsFinePurple,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyword,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Task 3: Review Insight Card
/// "The Quiet Advisor" Logic 구현
/// 사용자 별점과 NeedsFine 점수를 비교하여 분석 칩을 노출
class ReviewInsightCard extends StatelessWidget {
  final double userRating; // 0.0 ~ 5.0
  final double needsFineScore; // 0.0 ~ 100.0 or 0.0 ~ 5.0
  final String reviewText;
  final String userName;

  const ReviewInsightCard({
    super.key,
    required this.userRating,
    required this.needsFineScore,
    required this.reviewText,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 점수 정규화 (NeedsFine 점수가 100점 만점일 경우 5점 만점으로 변환)
    final double normalizedNeedsFineScore =
    needsFineScore > 5.0 ? needsFineScore / 20.0 : needsFineScore;

    final double scoreDiff = normalizedNeedsFineScore - userRating;

    // 2. Logic Implementation
    Widget? insightChip;

    if (scoreDiff >= 0.5) {
      // Case A: NeedsFine Score가 더 높음 (Appreciation)
      insightChip = _buildInsightChip(
        text: "✨ 글에 담긴 만족도가 더 높아요",
        textColor: kNeedsFinePurple,
        backgroundColor: kNeedsFinePurple.withOpacity(0.1),
      );
    } else if (scoreDiff <= -0.5) {
      // Case B: NeedsFine Score가 더 낮음 (Depreciation - 과장됨)
      insightChip = _buildInsightChip(
        text: "📉 조금 과장된 표현이 있어요",
        textColor: Colors.grey[700]!,
        backgroundColor: Colors.grey[200]!,
      );
    }
    // Case C: Neutral (차이가 미미함) -> No Chip (Visual Silence)

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: UserName & Rating & Insight Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 별점 (Amber Icons)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < userRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              const SizedBox(width: 8),

              // 조건부 Insight Chip 노출
              if (insightChip != null) insightChip,
            ],
          ),

          const SizedBox(height: 6),

          // User Name
          Text(
            userName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontFamily: 'NotoSansKR',
            ),
          ),

          const SizedBox(height: 8),

          // Review Content
          Text(
            reviewText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
              fontFamily: 'NotoSansKR',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightChip({
    required String text,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'NotoSansKR',
        ),
      ),
    );
  }
}