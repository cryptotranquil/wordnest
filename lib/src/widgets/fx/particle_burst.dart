import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that triggers a particle burst animation.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.child,
    this.particleCount = 12,
    this.duration = const Duration(milliseconds: 600),
    this.color = const Color(0xFFFFD700),
  });

  final Widget child;
  final int particleCount;
  final Duration duration;
  final Color color;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _initParticles();

    if (!fxReduced(context)) {
      _controller.forward();
    }
  }

  void _initParticles() {
    final random = Random();
    _particles = List.generate(widget.particleCount, (index) {
      final angle = (index / widget.particleCount) * 2 * pi;
      final distance = 30 + random.nextDouble() * 20;
      return Particle(
        angle: angle,
        distance: distance,
        initialScale: 0.5 + random.nextDouble() * 0.5,
        initialOpacity: 0.8,
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
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (!fxReduced(context))
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                  color: widget.color,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
      ],
    );
  }
}

class Particle {
  Particle({
    required this.angle,
    required this.distance,
    required this.initialScale,
    required this.initialOpacity,
  });

  final double angle;
  final double distance;
  final double initialScale;
  final double initialOpacity;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  final List<Particle> particles;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final currentProgress = 1.0 - (1.0 - progress) * (1.0 - progress);
      final x = center.dx + cos(particle.angle) * particle.distance * currentProgress * progress;
      final y = center.dy + sin(particle.angle) * particle.distance * currentProgress * progress;

      final scale = particle.initialScale * (1.0 + progress);
      final opacity = particle.initialOpacity * (1.0 - progress);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 3 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}