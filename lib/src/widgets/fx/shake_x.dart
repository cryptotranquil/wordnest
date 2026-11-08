import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that performs a damped horizontal shake animation.
/// Triggered by changing the [key] parameter.
class ShakeX extends StatefulWidget {
  const ShakeX({
    super.key,
    required this.child,
    this.oscillations = 4,
    this.duration = const Duration(milliseconds: 320),
  });

  final Widget child;
  final int oscillations;
  final Duration duration;

  @override
  State<ShakeX> createState() => _ShakeXState();
}

class _ShakeXState extends State<ShakeX> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shake;
  String? _currentKey;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if widget key changed
    final newKey = widget.key.toString();
    if (newKey != _currentKey) {
      _currentKey = newKey;
      if (!fxReduced(context)) {
        _controller.forward();
      }
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
      animation: _shake,
      builder: (context, child) {
        // Damped oscillation - horizontal shake
        final t = _shake.value;
        final amplitude = 10.0 * (1 - t);
        final direction = (t * 100).floor() % 2 == 0 ? 1 : -1;
        final shakeOffset = amplitude * direction * (0.8 - t);

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: widget.child,
        );
      },
    );
  }
}