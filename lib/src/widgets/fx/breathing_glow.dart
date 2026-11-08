import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that creates a subtle pulsing glow effect (breathing).
class BreathingGlow extends StatefulWidget {
  const BreathingGlow({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.minScale = 1.0,
    this.maxScale = 1.05,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

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
      animation: _controller,
      builder: (context, child) {
        // Pulse between min and max for both scale and opacity
        final value = Curves.easeInOut.transform(_controller.value);
        final scale = widget.minScale + (widget.maxScale - widget.minScale) * (value.abs() * value.abs());
        final opacity = 0.3 + 0.3 * value.abs();

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    spreadRadius: 4,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}