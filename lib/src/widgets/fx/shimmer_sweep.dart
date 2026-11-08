import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that sweeps a highlight across its child.
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.color = const Color(0x33FFFFFF),
  });

  final Widget child;
  final Duration duration;
  final Color color;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -0.5, end: 1.5).animate(_controller);

    if (!fxReduced(context)) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (fxReduced(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ShimmerPainter(
            animationValue: _animation.value,
            color: widget.color,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.animationValue,
    required this.color,
  });

  final double animationValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Create a sweep gradient that moves from left to right
    final shader = LinearGradient(
      colors: [color, color.withValues(alpha: 0.5), color],
      stops: [0.0, 0.3, 0.6],
    ).createShader(
      Rect.fromLTWH(
        animationValue * size.width - size.width,
        0,
        size.width * 2,
        size.height,
      ),
    );

    paint.shader = shader;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}