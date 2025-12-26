import 'package:flutter/material.dart';
import 'package:needsfine_app/models/app_data.dart';

class ReviewCard extends StatefulWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;
  late Animation<int> _trustAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _scoreAnimation = Tween<double>(begin: 0, end: widget.review.needsfineScore).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    _trustAnimation = IntTween(begin: 0, end: widget.review.trustLevel).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTrusted = widget.review.trustLevel >= 70;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isTrusted ? const Color(0xFF9C7CFF).withOpacity(0.5) : Colors.grey.shade200),
      ),
      color: isTrusted ? const Color(0xFFF0E9FF).withOpacity(0.5) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Text(widget.review.content, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF1E1E1E))),
            const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(radius: 20, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E1E))),
            Text(widget.review.date, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [ const Icon(Icons.star, color: Colors.amber, size: 16), Text(widget.review.rating.toStringAsFixed(1))]),
                Text("신뢰도 ${_trustAnimation.value}%", style: TextStyle(color: _trustAnimation.value > 80 ? Colors.deepPurple : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            );
          },
        )
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9C7CFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '니즈파인 점수 ${_scoreAnimation.value.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );
          },
        ),
        Wrap(
          spacing: 6,
          children: widget.review.tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, backgroundColor: Colors.grey[200])).toList(),
        )
      ],
    );
  }
}
