import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wordnest/src/data/chapter.dart';
import 'package:wordnest/src/data/levels.dart';
import 'package:wordnest/src/screens/gameplay_screen.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/scenic_background.dart';

/// A single, vertically scrolling journey through all chapters.
class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({super.key, required this.player});

  final PlayerState player;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: player,
          builder: (context, _) {
            final current = ChapterBook.chapterForLevel(player.currentLevel) ??
                ChapterBook.chapters.last;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Chapters & Journey', style: AppText.quicksand(24, weight: 700))),
                    _JourneyBadge(text: 'Ch. ${current.id}', icon: Icons.auto_stories_outlined),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Your journey, one word at a time', style: AppText.label(12, color: AppColors.muted)),
                const SizedBox(height: 24),
                for (final chapter in ChapterBook.chapters) ...[
                  _ChapterCard(chapter: chapter, currentLevel: player.currentLevel),
                  _JourneyPath(chapter: chapter, player: player),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JourneyBadge extends StatelessWidget {
  const _JourneyBadge({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: .65), borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.teal, size: 15),
          const SizedBox(width: 5),
          Text(text, style: AppText.label(11, color: AppColors.cream)),
        ]),
      );
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.currentLevel});
  final Chapter chapter;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final isCurrent = currentLevel >= chapter.levelStart && currentLevel <= chapter.levelEnd;
    final isLocked = currentLevel < chapter.levelStart;
    final palette = switch (chapter.themeKey) {
      'ocean' => ScenePalette.dusk,
      'cosmos' => ScenePalette.night,
      _ => ScenePalette.dawn,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF11302F),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 100, width: double.infinity, child: Stack(fit: StackFit.expand, children: [
            ScenicBackground(palette: palette, scrim: SceneScrim.sheet),
            Positioned(left: 14, bottom: 12, child: _JourneyBadge(
              text: isCurrent ? 'Currently exploring' : isLocked ? 'Locked' : 'Chapter complete',
              icon: isCurrent ? Icons.explore_outlined : isLocked ? Icons.lock_outline : Icons.check_circle_outline,
            )),
          ])),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Chapter ${chapter.id}  •  ${chapter.name}', style: AppText.quicksand(19, weight: 700)),
              const SizedBox(height: 5),
              Text('Levels ${chapter.levelStart}–${chapter.levelEnd}${isLocked ? '  •  Unlocks after level ${chapter.unlockAfterLevel}' : ''}',
                style: AppText.label(12, color: AppColors.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _JourneyPath extends StatelessWidget {
  const _JourneyPath({required this.chapter, required this.player});
  final Chapter chapter;
  final PlayerState player;
  static const double spacing = 86;

  @override
  Widget build(BuildContext context) {
    final count = chapter.levelEnd - chapter.levelStart + 1;
    // Only actual levels can open. LevelBook's fallback would otherwise open a
    // different puzzle under the number the player tapped.
    final available = LevelBook.all.map((level) => level.number).toSet();
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final points = List<Offset>.generate(count, (i) => Offset(
        width * (.5 + .25 * math.sin(i * .72)), 46 + i * spacing));
      return SizedBox(
        height: 92 + (count - 1) * spacing,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _JourneyPainter(points))),
          for (var i = 0; i < count; i++)
            Positioned(
              left: points[i].dx - 42,
              top: points[i].dy - 25,
              width: 84,
              child: _LevelNode(
                level: chapter.levelStart + i,
                currentLevel: player.currentLevel,
                available: available.contains(chapter.levelStart + i),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => GameplayScreen(level: LevelBook.level(chapter.levelStart + i), player: player),
                )),
              ),
            ),
        ]),
      );
    });
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level, required this.currentLevel, required this.available, required this.onTap});
  final int level;
  final int currentLevel;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = level == currentLevel && available;
    final cleared = level < currentLevel && available;
    final playable = available && level <= currentLevel;
    final label = !available ? 'Coming soon' : current ? 'Current' : cleared ? 'Replay' : 'Locked';
    return Semantics(
      button: playable,
      label: 'Level $level, $label',
      child: InkWell(
        onTap: playable ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Column(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: playable ? AppColors.gold : const Color(0xFF173635),
              border: Border.all(color: playable ? AppColors.goldLight : AppColors.muted.withValues(alpha: .45), width: current ? 2 : 1),
              boxShadow: current ? [BoxShadow(color: AppColors.gold.withValues(alpha: .3), blurRadius: 18)] : null,
            ),
            alignment: Alignment.center,
            child: Text('$level', style: AppText.label(15, weight: 700, color: playable ? AppColors.ink : AppColors.muted)),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: AppText.label(10, color: current ? AppColors.gold : AppColors.muted)),
        ]),
      ),
    );
  }
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      path.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    final paint = Paint()..color = AppColors.teal.withValues(alpha: .45);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 8) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) canvas.drawCircle(tangent.position, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter oldDelegate) => oldDelegate.points != points;
}
