import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A pressable widget that scales to 0.96 with a soft overshoot and back.
/// Plays optional haptic and UI tap sound.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onHaptic,
    this.onUiTapSound,
  });

  final Widget child;
  final GestureTapCallback onTap;
  final VoidCallback? onHaptic;
  final VoidCallback? onUiTapSound;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _pressed = false;

  static final Curve _overshootCurve = const ElasticOutCurve(0.65);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: _overshootCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
    if (fxReduced(context)) {
      widget.onTap();
      return;
    }
    setState(() => _pressed = true);
    _controller.forward();
    widget.onHaptic?.call();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    widget.onUiTapSound?.call();
  }

  void _handleTapCancel() {
    if (!mounted) return;
  }

  void _handleTap() {
    if (!mounted) return;
    if (_pressed) {
      _controller.reverse();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          widget.onTap();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fxReduced(context)) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.96 + (_scale.value * 0.04),
            child: widget.child,
          );
        },
      ),
    );
  }
}