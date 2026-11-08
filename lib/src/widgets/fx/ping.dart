import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that creates a pulsing ping effect (scale up then down).
class Ping extends StatefulWidget {
  const Ping({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
  });

  final Widget child;
  final Duration duration;

  @override
  State<Ping> createState() => _PingState();
}

class _PingState extends State<Ping> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  bool _isReduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = Tween(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkReducedMotion();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkReducedMotion();
  }

  void _checkReducedMotion() {
    final reduced = fxReduced(context);
    if (!_isReduced && reduced) {
      _isReduced = true;
      _controller.stop();
    } else if (_isReduced && !reduced) {
      _isReduced = false;
      _controller.repeat(reverse: true);
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
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: widget.child,
        );
      },
    );
  }
}