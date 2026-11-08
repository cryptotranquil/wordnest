import 'package:flutter/material.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';

/// A widget that fades in and rises by 16px with a stagger delay based on index.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.step = 60,
  });

  final Widget child;
  final int index;
  final int step; // milliseconds per index

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: widget.index * widget.step);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
    _translate = Tween<Offset>(begin: const Offset(0, 0.016), end: Offset.zero)
        .animate(_controller);

    // Delay start based on index
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
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
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _translate,
          child: FadeTransition(
            opacity: _opacity,
            child: widget.child,
          ),
        );
      },
    );
  }
}