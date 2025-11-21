import 'package:flutter/material.dart';

class CrownPainter extends CustomPainter {
  final Color color;
  CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.9, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
