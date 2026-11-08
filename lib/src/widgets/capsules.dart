import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/wordnest_theme.dart';
import 'scenic_background.dart';

/// Level badge in the top-left, doubling as the way back to Home now that the
/// tab bar is gone.
class LevelPill extends StatelessWidget {
  const LevelPill({
    super.key,
    required this.level,
    this.onBack,
  });

  final int level;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onBack != null,
      label: 'Level $level${onBack != null ? ', back to home' : ''}',
      child: GestureDetector(
        onTap: onBack,
        child: Glass(
          height: AppMetrics.pillHeight,
          radius: AppMetrics.pillHeight / 2,
          padding: const EdgeInsets.only(left: 10, right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (onBack != null)
                const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              Text(
                'LEVEL',
                style: AppText.label(
                  12.5,
                  weight: 600,
                  color: AppColors.muted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$level',
                style: AppText.quicksand(15, color: AppColors.cream),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coin balance with the buy-more affordance.
class CoinPill extends StatelessWidget {
  const CoinPill({
    super.key,
    required this.coins,
    this.onAdd,
  });

  final int coins;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Glass(
      height: AppMetrics.pillHeight,
      radius: AppMetrics.pillHeight / 2,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CoinDisc(size: 26),
          const SizedBox(width: 9),
          Text(
            coins.toString().replaceAllMapped(
                  RegExp(r'(\d)(?=(\d{3})+$)'),
                  (m) => '${m[1]},',
                ),
            style: AppText.label(13.5, weight: 700, color: AppColors.cream),
          ),
          const SizedBox(width: 9),
          _PlusButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class CoinDisc extends StatelessWidget {
  const CoinDisc({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.36, -0.44),
          colors: <Color>[Color(0xFFFFE6AC), AppColors.gold, AppColors.goldDeep],
          stops: <double>[0, 0.6, 1],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x50000000), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
      child: Icon(
        Icons.star_rounded,
        size: size * 0.5,
        color: const Color(0xFF6B4500),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Get more coins',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.tealLift.withValues(alpha: 0.16),
            border: Border.all(color: AppColors.tealLift.withValues(alpha: 0.32)),
          ),
          child: const Icon(Icons.add_rounded, size: 16, color: AppColors.tealLift),
        ),
      ),
    );
  }
}

/// Bonus-word progress. Tapping opens the collected-words sheet.
class BonusPill extends StatelessWidget {
  const BonusPill({
    super.key,
    required this.found,
    required this.total,
    this.onTap,
  });

  final int found;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bonus words, $found of $total',
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          height: AppMetrics.smallPillHeight,
          radius: AppMetrics.smallPillHeight / 2,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.menu_book_rounded, size: 15, color: AppColors.tealLift),
              const SizedBox(width: 8),
              Text('Bonus words', style: AppText.label(12, weight: 600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$found / $total',
                  style: AppText.label(
                    11,
                    weight: 700,
                    color: AppColors.goldInk,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The letters currently held on the wheel — the "string" in the canvas.
class StringPill extends StatelessWidget {
  const StringPill({
    super.key,
    required this.input,
    this.feedback = WordFeedback.none,
  });

  final String input;
  final WordFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final isInvalid = feedback != WordFeedback.none;
    final letters = input.split('');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: AppMetrics.pillHeight,
      constraints: const BoxConstraints(minWidth: 134),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xA807191D),
        borderRadius: BorderRadius.circular(AppMetrics.pillHeight / 2),
        border: Border.all(
          color: isInvalid
              ? AppColors.danger.withValues(alpha: 0.6)
              : AppColors.glassLine,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (letters.isEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(
                3,
                (i) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < letters.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  letters[i],
                  style: AppText.quicksand(
                    17,
                    color: isInvalid ? AppColors.danger : AppColors.cream,
                  ),
                ),
              ),
          const SizedBox(width: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInvalid ? AppColors.danger : AppColors.tealLift,
              boxShadow: isInvalid
                  ? null
                  : const <BoxShadow>[
                      BoxShadow(color: AppColors.tealLift, blurRadius: 9),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading used on Home ("Today") and inside sheets.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(text, style: AppText.quicksand(15, color: AppColors.cream)),
        ?trailing,
      ],
    );
  }
}
