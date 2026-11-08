import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/wordnest_theme.dart';
import '../widgets/controls.dart';

/// The level-complete sheet from the canvas: stars, coin reward, level stats
/// and the next action. Share is intentionally absent from the MVP.
class LevelCompleteSheet extends StatelessWidget {
  const LevelCompleteSheet({
    super.key,
    required this.controller,
    required this.hasNext,
    required this.onReplay,
    required this.onNext,
    required this.onClose,
  });

  final GameController controller;
  final bool hasNext;
  final VoidCallback onReplay;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final double precision = controller.precision * 100;
    final int precisionRounded = precision.round();

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppMetrics.sheetRadius)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xE610262A), Color(0xF708181C)],
        ),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x73000000), offset: Offset(0, -20), blurRadius: 50),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      controller.level.chapter,
                      style: AppText.label(11.5, weight: 600, color: AppColors.muted),
                    ),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Close',
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: const Icon(Icons.close_rounded, size: 15, color: AppColors.text),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Level complete',
              textAlign: TextAlign.center,
              style: AppText.quicksand(31, color: AppColors.cream, letterSpacing: -0.3),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StarBadge(label: 'Speed', earned: controller.earnedSpeed),
                const SizedBox(width: 26),
                StarBadge(label: 'Mastery', earned: controller.earnedMastery),
                const SizedBox(width: 26),
                StarBadge(label: 'Lexicon', earned: controller.earnedLexicon),
              ],
            ),
            const SizedBox(height: 18),
            _RewardStrip(coins: controller.coinsAwarded),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCell(
                    label: 'Words',
                    value: '${controller.solvedWordCount} / ${controller.wordTotal}',
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: _StatCell(label: 'Precision', value: '$precisionRounded%'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 7),
                    Text('Bonus words', style: AppText.label(11.5, weight: 600)),
                  ],
                ),
                Text(
                  '${controller.bonusFound} / ${controller.bonusTotal}',
                  style: AppText.label(11.5, weight: 700, color: const Color(0xFFFFD27A)),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: ColoredBox(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: controller.bonusTotal == 0
                          ? 0
                          : controller.bonusFound / controller.bonusTotal,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[AppColors.teal, AppColors.gold],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: hasNext ? 'Next level' : 'Back to home',
              onTap: onNext,
              icon: hasNext ? Icons.arrow_forward_rounded : Icons.home_rounded,
            ),
            const SizedBox(height: 9),
            SecondaryButton(label: 'Replay', onTap: onReplay),
            const SizedBox(height: 14),
            Text(
              '“A quiet mind discovers every answer.”',
              textAlign: TextAlign.center,
              style: AppText.label(
                11.5,
                weight: 500,
                color: Colors.white.withValues(alpha: 0.58),
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardStrip extends StatelessWidget {
  const _RewardStrip({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.gold.withValues(alpha: 0.09),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.36, -0.44),
                colors: <Color>[Color(0xFFFFE6AC), AppColors.gold, AppColors.goldDeep],
                stops: <double>[0, 0.6, 1],
              ),
            ),
            child: const Icon(Icons.star_rounded, size: 16, color: Color(0xFF6B4500)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Coins earned',
              style: AppText.label(12.5, weight: 600, color: const Color(0xFFFFE4AE)),
            ),
          ),
          Text(
            '+$coins',
            style: AppText.quicksand(17, color: const Color(0xFFFFD27A)),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      color: const Color(0xEB091A1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppText.label(
              9.5,
              weight: 700,
              color: AppColors.muted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: AppText.quicksand(17, color: AppColors.cream)),
        ],
      ),
    );
  }
}
