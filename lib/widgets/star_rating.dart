// lib/widgets/star_rating.dart
import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final Color color;
  final double size;

  const StarRating({
    Key? key,
    required this.rating,
    this.color = const Color(0xFFFFCC15), // 기본 노란색
    this.size = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating % 1) >= 0.5;

    // 꽉 찬 별
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: color, size: size));
    }

    // 반쪽 별
    if (hasHalfStar && fullStars < 5) {
      stars.add(Icon(Icons.star_half, color: color, size: size));
    }

    // 빈 별
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.grey[300], size: size));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }
}
