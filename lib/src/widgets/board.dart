import 'package:flutter/material.dart';

import '../models/level.dart';
import '../state/game_controller.dart';
import '../theme/wordnest_theme.dart';

/// Porcelain letter tile — cream face, solid bottom bevel, soft drop shadow.
class LetterTile extends StatelessWidget {
  const LetterTile({
    super.key,
    required this.letter,
    required this.size,
    this.highlighted = false,
    this.revealed = false,
  });

  final String letter;
  final double size;
  final bool highlighted;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.creamTop, AppColors.creamBottom],
        ),
        boxShadow: <BoxShadow>[
          const BoxShadow(
            color: AppColors.bevel,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
          const BoxShadow(
            color: Color(0x57000000),
            offset: Offset(0, 10),
            blurRadius: 16,
          ),
          if (highlighted)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
        border: revealed
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: 1.4)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppText.quicksand(
          size * 0.5,
          color: AppColors.tileInk,
        ),
      ),
    );
  }
}

/// Untouched crossword cell — a glass frame with a single dot.
class EmptySlot extends StatelessWidget {
  const EmptySlot({
    super.key,
    required this.size,
    this.highlighted = false,
  });

  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        color: highlighted
            ? AppColors.gold.withValues(alpha: 0.12)
            : AppColors.slotFill,
        border: Border.all(
          color: highlighted
              ? AppColors.gold.withValues(alpha: 0.55)
              : AppColors.slotLine,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: highlighted ? 0.5 : 0.24),
        ),
      ),
    );
  }
}

/// The crossword itself. Every row keeps its leading gaps so the shape reads
/// correctly whichever entries are still unsolved.
class WordGrid extends StatelessWidget {
  const WordGrid({
    super.key,
    required this.controller,
    required this.cellSize,
    this.gap = AppMetrics.gridGap,
  });

  final GameController controller;
  final double cellSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = controller.level.shape;
    return Semantics(
      label:
          'Crossword board, ${controller.solvedWordCount} of ${controller.wordTotal} words found',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...<Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var colIndex = 0; colIndex < rows[rowIndex].length; colIndex++)
                  Padding(
                    padding: EdgeInsets.only(
                      left: colIndex == 0 ? 0 : gap,
                    ),
                    child: _cell(rows[rowIndex][colIndex]),
                  ),
              ],
            ),
            if (rowIndex != rows.length - 1) SizedBox(height: gap),
          ],
        ],
      ),
    );
  }

  Widget _cell(GridCell? cell) {
    if (cell == null) {
      return SizedBox(width: cellSize, height: cellSize);
    }

    final letter = controller.visibleLetter(cell);
    final isHinted = controller.isShortcutHighlighted(cell);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: letter != null
          ? LetterTile(
              key: ValueKey<String>('tile-${cell.key}'),
              letter: letter,
              size: cellSize,
              highlighted: isHinted,
              revealed: controller.revealedCells.contains(cell.key),
            )
          : EmptySlot(
              key: ValueKey<String>('slot-${cell.key}'),
              size: cellSize,
              highlighted: isHinted,
            ),
    );
  }
}
