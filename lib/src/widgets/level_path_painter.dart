import 'package:flutter/material.dart';
import 'package:wordnest/src/data/chapter.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';

class LevelPathPainter extends CustomPainter {
  final int currentLevel;
  final Chapter chapter;

  LevelPathPainter({required this.currentLevel, required this.chapter});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final levelCount = chapter.levelEnd - chapter.levelStart + 1;
    final spacing = size.width / (levelCount - 1);

    // Draw the winding path
    for (int i = 0; i < levelCount - 1; i++) {
      final startX = i * spacing;
      final startY = i % 2 == 0 ? size.height * 0.3 : size.height * 0.7;
      final endX = (i + 1) * spacing;
      final endY = (i + 1) % 2 == 0 ? size.height * 0.3 : size.height * 0.7;

      if (i == 0) {
        path.moveTo(startX, startY);
      }
      path.cubicTo(
        startX + spacing * 0.3, startY,
        endX - spacing * 0.3, endY,
        endX, endY,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}