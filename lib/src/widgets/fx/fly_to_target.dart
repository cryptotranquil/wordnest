import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that flies from a source GlobalKey position to a target GlobalKey position
/// along a curved arc.
class FlyToTarget extends StatefulWidget {
  const FlyToTarget({
    super.key,
    required this.sourceKey,
    required this.targetKey,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDelay = 0,
    this.onArrive,
  });

  final GlobalKey sourceKey;
  final GlobalKey targetKey;
  final Widget child;
  final Duration duration;
  final int staggerDelay; // milliseconds
  final VoidCallback? onArrive;

  @override
  State<FlyToTarget> createState() => _FlyToTargetState();
}

class _FlyToTargetState extends State<FlyToTarget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    // Apply stagger delay
    Future.delayed(Duration(milliseconds: widget.staggerDelay), () {
      if (mounted && !fxReduced(context)) {
        _startAnimation();
      }
    });
  }

  void _startAnimation() async {
    // Wait a frame for layout
    await Future.delayed(const Duration(milliseconds: 1));
    if (!mounted) return;

    final sourceRenderBox = widget.sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final targetRenderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (sourceRenderBox == null || targetRenderBox == null || !sourceRenderBox.hasSize || !targetRenderBox.hasSize) {
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    _controller.addListener(() {
      if (_controller.isCompleted && widget.onArrive != null) {
        widget.onArrive!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (fxReduced(context)) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final sourceRenderBox = widget.sourceKey.currentContext?.findRenderObject() as RenderBox?;
        final targetRenderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;

        if (sourceRenderBox == null || targetRenderBox == null) {
          return const SizedBox.shrink();
        }

        final sourcePosition = sourceRenderBox.localToGlobal(Offset.zero);
        final targetPosition = targetRenderBox.localToGlobal(Offset.zero);

        // Quadratic bezier curve calculation
        final t = _progress.value;
        final controlPoint = Offset(
          (sourcePosition.dx + targetPosition.dx) / 2,
          sourcePosition.dy - 100,
        );
        final position = Offset(
          sourcePosition.dx * (1 - t) + targetPosition.dx * t + 60 * t * (1 - t) * (controlPoint.dx - sourcePosition.dx),
          sourcePosition.dy * (1 - t) + targetPosition.dy * t + 60 * t * (1 - t) * (controlPoint.dy - sourcePosition.dy),
        );

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.scale(
            scale: 1.0 - _progress.value * 0.5,
            child: Opacity(
              opacity: 1.0 - _progress.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}