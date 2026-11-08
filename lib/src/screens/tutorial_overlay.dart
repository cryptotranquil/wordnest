import 'package:flutter/material.dart';

import '../theme/wordnest_theme.dart';

/// One coach mark: a title, a line of instruction, and the shape that the
/// spotlight should cut into the scrim.
class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    this.circular = false,
  });

  final String title;
  final String body;
  final bool circular;
}

/// Interactive first-run overlay: dims the game, highlights one control at a
/// time and hands control back once the player has seen all three steps.
class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.targets,
    required this.index,
    required this.onNext,
    required this.onSkip,
  });

  final List<TutorialStep> steps;
  final List<Rect> targets;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const double _tipWidth = 304;
  static const double _tipHeight = 172;

  @override
  Widget build(BuildContext context) {
    final step = steps[index];
    final target = index < targets.length ? targets[index] : Rect.zero;
    final hole = step.circular
        ? Rect.fromCircle(center: target.center, radius: target.shortestSide / 2 + 12)
        : target.inflate(10);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final above = hole.top > 320;
        final rawTop = above ? hole.top - _tipHeight - 16 : hole.bottom + 16;
        final top = rawTop.clamp(16.0, constraints.maxHeight - _tipHeight - 16);
        final left =
            ((constraints.maxWidth - _tipWidth) / 2).clamp(12.0, constraints.maxWidth - _tipWidth - 12);

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(hole: hole, circular: step.circular),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: _tipWidth,
              child: _TipCard(
                step: step,
                index: index,
                total: steps.length,
                above: above,
                onNext: onNext,
                onSkip: onSkip,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.step,
    required this.index,
    required this.total,
    required this.above,
    required this.onNext,
    required this.onSkip,
  });

  final TutorialStep step;
  final int index;
  final int total;
  final bool above;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFA132C30), Color(0xFA0A1C20)],
            ),
            border: Border.all(color: AppColors.tealLift.withValues(alpha: 0.28)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                offset: const Offset(0, 22),
                blurRadius: 50,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      for (var i = 0; i < total; i++)
                        Container(
                          width: i == index ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == index
                                ? AppColors.tealLift
                                : Colors.white.withValues(alpha: 0.2),
                            boxShadow: i == index
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.tealLift.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'STEP ${index + 1} OF $total',
                    style: AppText.label(
                      10,
                      weight: 700,
                      color: AppColors.tealLift.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(step.title, style: AppText.quicksand(18, color: AppColors.cream)),
              const SizedBox(height: 6),
              Text(
                step.body,
                style: AppText.label(
                  12.5,
                  weight: 500,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: onSkip,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                      child: Text(
                        'Skip',
                        style: AppText.label(
                          12,
                          weight: 600,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onNext,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Color(0xFF189C90), Color(0xFF0C6B63)],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.36),
                            offset: const Offset(0, 8),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            isLast ? 'Got it' : 'Next',
                            style: AppText.label(
                              12.5,
                              weight: 700,
                              color: const Color(0xFFF2FFFD),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFFF2FFFD),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: _TipCard._arrowOffset,
          top: above ? null : -7,
          bottom: above ? -7 : null,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: above ? const Color(0xFF0C2226) : const Color(0xFF0E262A),
                border: Border(
                  right: BorderSide(
                    color: AppColors.tealLift.withValues(alpha: 0.28),
                  ),
                  bottom: BorderSide(
                    color: AppColors.tealLift.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static double get _arrowOffset => (TutorialOverlay._tipWidth - 14) / 2;
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.hole, required this.circular});

  final Rect hole;
  final bool circular;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());

    canvas.drawRect(bounds, Paint()..color = const Color(0xD1030C11));

    final clear = Paint()..blendMode = BlendMode.clear;
    if (circular) {
      canvas.drawOval(hole, clear);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole, const Radius.circular(20)),
        clear,
      );
    }

    canvas.restore();

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.tealLift.withValues(alpha: 0.5);
    if (circular) {
      canvas.drawOval(hole, ring);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole, const Radius.circular(20)),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.circular != circular;
}
