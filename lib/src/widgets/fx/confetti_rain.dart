import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that triggers a confetti rain animation from top to bottom.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({
    super.key,
    this.count = 50,
    this.duration = const Duration(milliseconds: 1500),
    this.colors = const [
      Color(0xFFE74C3C),
      Color(0xFF9B59B6),
      Color(0xFF3498DB),
      Color(0xFF2ECC71),
      Color(0xFFF39C12),
    ],
  });

  final int count;
  final Duration duration;
  final List<Color> colors;

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _initParticles();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !fxReduced(context)) {
        _controller.forward();
      }
    });
  }

  void _initParticles() {
    final random = math.Random();
    _particles = List.generate(widget.count, (index) {
      return ConfettiParticle(
        angle: random.nextDouble() * 2 * math.pi,
        startX: random.nextDouble(),
        startXOffset: random.nextDouble() * 20,
        startY: -0.1 - (index / widget.count) * 0.1,
        size: 2 + random.nextDouble() * 4,
        color: widget.colors[random.nextInt(widget.colors.length)],
        rotation: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.1,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConfettiPainter(
        particles: _particles,
        progress: _controller.value,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class ConfettiParticle {
  ConfettiParticle({
    required this.angle,
    required this.startX,
    required this.startXOffset,
    required this.startY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });

  final double angle;
  final double startX;
  final double startXOffset;
  final double startY;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  final List<ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;

      final progressEase = Curves.easeOutQuad.transform(progress);

      final x = size.width * particle.startX +
          particle.startXOffset +
          (math.cos(particle.angle) * 100 * progressEase);
      final y = size.height * particle.startY +
          math.sin(particle.angle) * 100 * progressEase +
          particle.startY * size.height * progressEase * 2;

      final rotation = particle.rotation + particle.rotationSpeed * progressEase * 100;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw a rectangle confetti
      final rect = Rect.fromLTWH(-particle.size, -particle.size / 2, particle.size, particle.size / 2);
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}