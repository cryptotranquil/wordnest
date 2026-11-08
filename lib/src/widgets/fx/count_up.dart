import 'package:flutter/material.dart';

/// Animates an integer from a value to b with an ease-out curve.
class CountUp extends StatefulWidget {
  const CountUp({
    super.key,
    required this.from,
    required this.to,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
    Curve? curve,
  })  : _curve = curve ?? Curves.easeOut,
        super();

  final int from;
  final int to;
  final Widget Function(BuildContext context, int value) builder;
  final Duration duration;
  final Curve _curve;

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget._curve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = (widget.from + (_animation.value * (widget.to - widget.from)).round());
        return widget.builder(context, value);
      },
    );
  }
}