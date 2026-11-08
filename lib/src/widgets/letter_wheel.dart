import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/wordnest_theme.dart';

/// The circular letter platter. A single pointer gesture collects letters in
/// the order they are touched; releasing submits the word.
class LetterWheel extends StatefulWidget {
  const LetterWheel({
    super.key,
    required this.letters,
    required this.size,
    required this.onChanged,
    required this.onSubmit,
    required this.onShuffle,
    this.enabled = true,
  });

  final List<String> letters;
  final double size;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onShuffle;
  final bool enabled;

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel> {
  final List<int> _path = <int>[];
  int _turns = 0;

  double get _nodeSize => widget.size * 0.207;
  double get _orbit => widget.size / 2 - _nodeSize / 2 - 6;

  Offset _nodeCenter(int index) {
    final step = (math.pi * 2) / widget.letters.length;
    final angle = -math.pi / 2 + index * step;
    final c = widget.size / 2;
    return Offset(
      c + _orbit * math.cos(angle),
      c + _orbit * math.sin(angle),
    );
  }

  int? _hitTest(Offset local) {
    final threshold = _nodeSize * 0.72;
    for (var i = 0; i < widget.letters.length; i++) {
      if ((_nodeCenter(i) - local).distance <= threshold) return i;
    }
    return null;
  }

  void _select(Offset local, {required bool reset}) {
    if (!widget.enabled) return;
    if (reset) {
      _path.clear();
    }
    final hit = _hitTest(local);
    if (hit == null) return;

    if (_path.isNotEmpty && _path.last == hit) return;

    // Dragging back over the previous letter removes the last pick.
    if (_path.length >= 2 && _path[_path.length - 2] == hit) {
      setState(_path.removeLast);
      widget.onChanged(_word);
      HapticFeedback.selectionClick();
      return;
    }

    if (_path.contains(hit)) return;

    setState(() => _path.add(hit));
    widget.onChanged(_word);
    HapticFeedback.selectionClick();
  }

  String get _word => _path.map((i) => widget.letters[i]).join();

  void _end() {
    if (_path.isEmpty) return;
    final word = _word;
    setState(_path.clear);
    widget.onChanged('');
    widget.onSubmit(word);
  }

  @override
  Widget build(BuildContext context) {
    final points = <Offset>[for (final i in _path) _nodeCenter(i)];

    return SizedBox(
      width: widget.size,
      height: widget.size,
      // Raw pointer events rather than a pan recogniser: every pointer-up ends
      // the swipe, even when the gesture arena hands the drag to something else.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent d) => _select(d.localPosition, reset: true),
        onPointerMove: (PointerMoveEvent d) => _select(d.localPosition, reset: false),
        onPointerUp: (PointerUpEvent _) => _end(),
        onPointerCancel: (PointerCancelEvent _) => _end(),
        child: Stack(
          children: <Widget>[
            // Platter.
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -0.36),
                  radius: 0.86,
                  colors: <Color>[
                    const Color(0xFF286E68).withValues(alpha: 0.42),
                    const Color(0xFF071E22).withValues(alpha: 0.16),
                    const Color(0xFF061A1E).withValues(alpha: 0),
                  ],
                  stops: const <double>[0, 0.66, 1],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),

            if (points.length > 1)
              Positioned.fill(
                child: CustomPaint(
                  painter: _RibbonPainter(points),
                ),
              ),

            for (var i = 0; i < widget.letters.length; i++)
              Positioned(
                left: _nodeCenter(i).dx - _nodeSize / 2,
                top: _nodeCenter(i).dy - _nodeSize / 2,
                child: _WheelNode(
                  letter: widget.letters[i],
                  size: _nodeSize,
                  selected: _path.contains(i),
                ),
              ),

            // Shuffle sits in the middle of the platter.
            Center(
              child: Semantics(
                button: true,
                label: 'Shuffle letters',
                child: GestureDetector(
                  onTap: () {
                    setState(() => _turns++);
                    widget.onShuffle();
                  },
                  child: AnimatedRotation(
                    turns: _turns.toDouble(),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xA8091E22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: const Icon(
                        Icons.shuffle_rounded,
                        size: 21,
                        color: Color(0xFFD7ECEA),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelNode extends StatelessWidget {
  const _WheelNode({
    required this.letter,
    required this.size,
    required this.selected,
  });

  final String letter;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: selected
              ? <Color>[AppColors.tealBright, AppColors.tealDeep]
              : <Color>[const Color(0xFFFFFDF4), const Color(0xFFF2E2C4)],
        ),
        boxShadow: selected
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x8C9FF3E8),
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Color(0x8046D6C6),
                  blurRadius: 26,
                ),
              ]
            : const <BoxShadow>[
                BoxShadow(
                  color: AppColors.bevel,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x5C000000),
                  offset: Offset(0, 8),
                  blurRadius: 14,
                ),
              ],
      ),
      child: Text(
        letter,
        style: AppText.quicksand(
          size * 0.44,
          color: selected ? const Color(0xFFEAFFFB) : const Color(0xFF0D3F3B),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    // Glow underlay.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF46D6C6).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Bright core.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = ui.Gradient.linear(
          points.first,
          points.last,
          const <Color>[Color(0xFFBDFFF6), AppColors.teal],
        ),
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      (points.isNotEmpty &&
          oldDelegate.points.isNotEmpty &&
          oldDelegate.points.last != points.last);
}
