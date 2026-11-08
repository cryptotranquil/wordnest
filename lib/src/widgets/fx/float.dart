import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that performs a looping bob motion (+-3px over 3 seconds).
class Float extends StatefulWidget {
  const Float({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3000),
  });

  final Widget child;
  final Duration duration;

  @override
  State<Float> createState() => _FloatState();
}

class _FloatState extends State<Float> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Bob motion: +-3px sinusoidal
    _yOffset = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      animation: _yOffset,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yOffset.value),
          child: widget.child,
        );
      },
    );
  }
}