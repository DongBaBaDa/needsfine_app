import 'package:flutter/material.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/widgets/feedback_indicator.dart'; // 피드백 재사용

class StoreReviewsScreen extends StatelessWidget {
  final Store store;

  const StoreReviewsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(store.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: store.reviews.length,
        separatorBuilder: (context, index) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final review = store.reviews[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 헤더 (작성자, 날짜, 별점)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(review.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFF9C7CFF)),
                        const SizedBox(width: 4),
                        Text(review.rating.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. 내용
              Text(review.content, style: const TextStyle(fontSize: 15, height: 1.4)),
              const SizedBox(height: 12),

              // 3. 사진 (있으면)
              if (review.photoUrls.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.photoUrls[idx],
                          width: 100, height: 100, fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // 4. 니즈파인 분석 태그 (Authenticity, Tags)
              Wrap(
                spacing: 6,
                children: [
                  if (review.authenticity)
                    _buildTag("신뢰할 수 있는 리뷰", Colors.green[50]!, Colors.green),
                  ...review.tags.map((t) => _buildTag("#$t", Colors.grey[100]!, Colors.black54)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Chip(
      label: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}