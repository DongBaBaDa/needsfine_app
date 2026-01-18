import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class CategoryPlaceholderScreen extends StatelessWidget {
  final String title;
  const CategoryPlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: const Text(
            '준비중입니다.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kNeedsFinePurple),
          ),
        ),
      ),
    );
  }
}
