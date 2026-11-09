import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:wordnest/src/data/chapter.dart';
import 'package:wordnest/src/data/levels.dart';
import 'package:wordnest/src/screens/gameplay_screen.dart';
import 'package:wordnest/src/screens/shop_screen.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/capsules.dart';
import 'package:wordnest/src/widgets/panel_kit.dart';

/// Chapters & Journey: one long vertical path through every chapter.
///
/// Reads progress from [PlayerState.currentLevel]. Stars and milestone
/// rewards are display-only for now (step 2 stores them).
class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key, required this.player, this.onGoHome});

  final PlayerState player;

  /// Called by the back arrow and the Home chip (switches the shell tab).
  final VoidCallback? onGoHome;

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

enum _ChapterState { completed, current, locked }

class _Milestone {
  const _Milestone(this.name, this.reward);
  final String name;
  final int reward;
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  static const double _rowHeight = 118;
  static const double _nodeWidth = 120;

  /// Reward chests at every 10th level.
  static const Map<int, _Milestone> _milestones = <int, _Milestone>{
    10: _Milestone('Mossy Cache', 50),
    20: _Milestone('Sanctuary Relic', 100),
    30: _Milestone('Sunken Treasure', 100),
    40: _Milestone('Pearl Vault', 150),
    50: _Milestone('Nebula Cache', 100),
    60: _Milestone('Cosmic Crown', 200),
  };

  final GlobalKey _currentKey = GlobalKey();
  bool _scrolledToCurrent = false;

  int get _totalLevels => ChapterBook.chapters.last.levelEnd;

  @override
  Widget build(BuildContext context) {
    if (!_scrolledToCurrent) {
      _scrolledToCurrent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? target = _currentKey.currentContext;
        if (target != null && mounted) {
          Scrollable.ensureVisible(
            target,
            alignment: 0.4,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: PanelColors.bgBottom,
      body: PanelBackdrop(
        child: SafeArea(
          bottom: false,
          child: PhoneFrame(
            child: AnimatedBuilder(
              animation: widget.player,
              builder: (BuildContext context, Widget? _) {
                final int cur = widget.player.currentLevel;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _topBar(),
                      const SizedBox(height: 18),
                      _titleRow(cur),
                      const SizedBox(height: 16),
                      _journeyCard(cur),
                      for (final Chapter ch in ChapterBook.chapters) ...<Widget>[
                        const SizedBox(height: 18),
                        _ChapterBanner(chapter: ch, state: _stateOf(ch, cur), currentLevel: cur),
                        _levelPath(ch, cur),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  _ChapterState _stateOf(Chapter ch, int cur) {
    if (ch.levelEnd < cur) return _ChapterState.completed;
    if (ch.levelStart > cur) return _ChapterState.locked;
    return _ChapterState.current;
  }

  // ------------------------------------------------------------------ header

  Widget _topBar() {
    return Row(
      children: <Widget>[
        HeaderPill(label: 'Home', icon: Icons.eco_rounded, onTap: widget.onGoHome),
        const Spacer(),
        CoinPill(
          coins: widget.player.coins,
          onAdd: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ShopScreen(player: widget.player)),
          ),
        ),
      ],
    );
  }

  Widget _titleRow(int cur) {
    final Chapter chapter = ChapterBook.chapterForLevel(cur) ?? ChapterBook.chapters.last;
    final int shown = cur.clamp(1, _totalLevels);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: widget.onGoHome,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: PanelColors.pill, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.cream, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Chapters & Journey',
                maxLines: 2,
                style: AppText.quicksand(26, weight: 700, color: Colors.white, height: 1.1),
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Word Sanctuary Realm',
                    style: AppText.label(13, weight: 500, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        HeaderPill(
          label: 'Ch. ${chapter.id} · $shown/$_totalLevels',
          icon: Icons.map_outlined,
          iconColor: AppColors.gold,
          labelColor: AppColors.gold,
        ),
      ],
    );
  }

  Widget _journeyCard(int cur) {
    final int shown = cur.clamp(1, _totalLevels);
    return PanelCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      radius: 22,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Your journey', style: AppText.quicksand(18, weight: 700, color: Colors.white)),
              const Spacer(),
              Text(
                'Level $shown of $_totalLevels',
                style: AppText.label(13, weight: 500, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SlimProgress(
            value: (cur - 1) / _totalLevels,
            height: 8,
            gradient: const LinearGradient(colors: <Color>[AppColors.teal, AppColors.gold]),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final Chapter ch in ChapterBook.chapters)
                Text(ch.name, style: AppText.label(11.5, weight: 500, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ path

  Widget _levelPath(Chapter ch, int cur) {
    final int count = ch.levelEnd - ch.levelStart + 1;
    final double height = count * _rowHeight + 24;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth;
        final double amp = (w / 2 - _nodeWidth / 2).clamp(30.0, 150.0) * 0.85;

        Offset centerOf(int i) {
          final int level = ch.levelStart + i;
          return Offset(
            w / 2 + amp * math.sin(level * 0.95),
            30 + i * _rowHeight + 36,
          );
        }

        final List<Offset> points = <Offset>[for (int i = 0; i < count; i++) centerOf(i)];

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    points: points,
                    firstLevel: ch.levelStart,
                    currentLevel: cur,
                  ),
                ),
              ),
              for (int i = 0; i < count; i++) _positionedNode(ch.levelStart + i, centerOf(i), cur),
            ],
          ),
        );
      },
    );
  }

  Widget _positionedNode(int level, Offset c, int cur) {
    final bool isCurrent = level == cur;
    final bool isMilestone = _milestones.containsKey(level);
    final double radius = isMilestone ? 33 : (isCurrent ? 42 : 31);
    // The current node carries a tooltip above it.
    final double extraTop = isCurrent && !isMilestone ? 38 : 0;

    return Positioned(
      left: c.dx - _nodeWidth / 2,
      top: c.dy - radius - extraTop,
      width: _nodeWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTapLevel(level, cur),
        child: isMilestone
            ? _milestoneNode(level, cur)
            : isCurrent
                ? _currentNode(level)
                : level < cur
                    ? _clearedNode(level)
                    : _lockedNode(level),
      ),
    );
  }

  void _onTapLevel(int level, int cur) {
    if (level > cur) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Finish level $cur to unlock this one.')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(level: LevelBook.level(level), player: widget.player),
      ),
    );
  }

  /// Placeholder until per-level stars are stored (step 2).
  int _starsFor(int level) => 3;

  Widget _stars(int filled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Icon(
              Icons.star_rounded,
              size: 14,
              color: i < filled ? AppColors.gold : const Color(0xFF34494A),
            ),
          ),
      ],
    );
  }

  Widget _clearedNode(int level) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 70,
          height: 62,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 4,
                top: 0,
                child: Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: AppColors.goldDeep, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    '$level',
                    style: AppText.quicksand(24, weight: 700, color: AppColors.goldInk),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.tealDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: PanelColors.bgTop, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _stars(_starsFor(level)),
      ],
    );
  }

  Widget _currentNode(int level) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.ink),
              const SizedBox(width: 3),
              Text(
                'Tap to play',
                style: AppText.label(11.5, weight: 700, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: _currentKey,
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PanelColors.card,
            border: Border.all(color: AppColors.teal, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            '$level',
            style: AppText.quicksand(32, weight: 700, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Level $level',
          style: AppText.label(13, weight: 700, color: AppColors.tealLift),
        ),
      ],
    );
  }

  Widget _lockedNode(int level) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PanelColors.card.withValues(alpha: 0.6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
          ),
          child: Text(
            '$level',
            style: AppText.quicksand(22, weight: 700, color: AppColors.muted.withValues(alpha: 0.55)),
          ),
        ),
      ],
    );
  }

  Widget _milestoneNode(int level, int cur) {
    final _Milestone m = _milestones[level]!;
    final bool cleared = level < cur;
    final bool isCurrent = level == cur;
    final Color edge = cleared || isCurrent ? AppColors.gold : Colors.white.withValues(alpha: 0.16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          key: isCurrent ? _currentKey : null,
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PanelColors.card,
            border: Border.all(color: edge, width: 2.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                cleared
                    ? Icons.check_rounded
                    : isCurrent
                        ? Icons.play_arrow_rounded
                        : Icons.lock_rounded,
                size: 20,
                color: cleared || isCurrent ? AppColors.gold : AppColors.muted.withValues(alpha: 0.6),
              ),
              Text(
                'LVL $level',
                style: AppText.label(
                  10.5,
                  weight: 700,
                  color: cleared || isCurrent ? AppColors.cream : AppColors.muted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          m.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(
            11.5,
            weight: 700,
            color: cleared ? AppColors.cream : AppColors.muted.withValues(alpha: 0.7),
          ),
        ),
        Text(
          cleared ? '+${m.reward} claimed' : '+${m.reward}',
          style: AppText.label(
            11,
            weight: 700,
            color: cleared ? AppColors.teal : AppColors.gold,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed winding path

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.points,
    required this.firstLevel,
    required this.currentLevel,
  });

  final List<Offset> points;
  final int firstLevel;
  final int currentLevel;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final Offset a = points[i];
      final Offset b = points[i + 1];
      // A segment is "walked" once the level it leads to has been reached.
      final bool walked = firstLevel + i + 1 <= currentLevel;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = walked
            ? AppColors.gold.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.12);

      final double mid = (a.dy + b.dy) / 2;
      final Path curve = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);

      for (final PathMetric metric in curve.computeMetrics()) {
        double d = 0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, math.min(d + 9, metric.length)), paint);
          d += 17;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) =>
      old.currentLevel != currentLevel || old.points.length != points.length;
}

// ---------------------------------------------------------------------------
// Chapter banner (painted art, no image assets)

class _ChapterBanner extends StatelessWidget {
  const _ChapterBanner({
    required this.chapter,
    required this.state,
    required this.currentLevel,
  });

  final Chapter chapter;
  final _ChapterState state;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final int count = chapter.levelEnd - chapter.levelStart + 1;
    final bool locked = state == _ChapterState.locked;

    final String subtitle;
    switch (state) {
      case _ChapterState.completed:
        subtitle = 'Levels ${chapter.levelStart} to ${chapter.levelEnd} · $count/$count cleared';
      case _ChapterState.current:
        final int done = (currentLevel - chapter.levelStart + 1).clamp(1, count);
        subtitle = 'Levels ${chapter.levelStart} to ${chapter.levelEnd} · Level $done of $count';
      case _ChapterState.locked:
        subtitle =
            'Levels ${chapter.levelStart} to ${chapter.levelEnd} · Unlocks after Level ${chapter.unlockAfterLevel}';
    }

    return PanelCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 108,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CustomPaint(painter: _ArtPainter(chapter.themeKey)),
                  if (locked) ColoredBox(color: PanelColors.bgBottom.withValues(alpha: 0.62)),
                  Positioned(left: 12, bottom: 12, child: _chip()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Chapter ${chapter.id} · ${chapter.name}',
                  style: AppText.quicksand(
                    20,
                    weight: 700,
                    color: locked ? AppColors.muted : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.label(13, weight: 500, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip() {
    final IconData icon;
    final String label;
    final Color color;
    switch (state) {
      case _ChapterState.completed:
        icon = Icons.check_rounded;
        label = 'COMPLETED';
        color = AppColors.teal;
      case _ChapterState.current:
        icon = Icons.explore_outlined;
        label = 'CURRENTLY EXPLORING';
        color = AppColors.tealLift;
      case _ChapterState.locked:
        icon = Icons.lock_rounded;
        label = 'LOCKED';
        color = AppColors.muted;
    }
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: PanelColors.bgBottom.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.label(11, weight: 700, color: color, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

/// Small painted scene per chapter theme ('forest', 'ocean', 'cosmos').
class _ArtPainter extends CustomPainter {
  _ArtPainter(this.themeKey);

  final String themeKey;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    switch (themeKey) {
      case 'ocean':
        _ocean(canvas, size, rect);
      case 'cosmos':
        _cosmos(canvas, size, rect);
      default:
        _forest(canvas, size, rect);
    }
  }

  void _sky(Canvas canvas, Rect rect, Color top, Color bottom) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[top, bottom],
        ).createShader(rect),
    );
  }

  void _pine(Canvas canvas, double cx, double baseY, double h, Color color) {
    final Path p = Path()
      ..moveTo(cx, baseY - h)
      ..lineTo(cx + h * 0.32, baseY)
      ..lineTo(cx - h * 0.32, baseY)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  void _forest(Canvas canvas, Size s, Rect rect) {
    _sky(canvas, rect, const Color(0xFF2F6140), const Color(0xFF0F2C1E));
    // Light shaft
    final Path shaft = Path()
      ..moveTo(s.width * 0.52, 0)
      ..lineTo(s.width * 0.66, 0)
      ..lineTo(s.width * 0.78, s.height)
      ..lineTo(s.width * 0.46, s.height)
      ..close();
    canvas.drawPath(shaft, Paint()..color = const Color(0xFFB9E3A6).withValues(alpha: 0.22));
    const Color dark = Color(0xFF0B2318);
    for (final List<double> t in const <List<double>>[
      <double>[0.12, 70],
      <double>[0.24, 90],
      <double>[0.78, 84],
      <double>[0.9, 64],
      <double>[0.97, 50],
    ]) {
      _pine(canvas, s.width * t[0], s.height + 4, t[1], dark);
    }
  }

  void _ocean(Canvas canvas, Size s, Rect rect) {
    _sky(canvas, rect, const Color(0xFF1E5F7C), const Color(0xFF0A2236));
    canvas.drawCircle(
      Offset(s.width * 0.78, s.height * 0.3),
      16,
      Paint()..color = const Color(0xFFE9F6F2).withValues(alpha: 0.85),
    );
    for (int row = 0; row < 3; row++) {
      final Path wave = Path();
      final double y = s.height * (0.58 + row * 0.14);
      wave.moveTo(0, y);
      for (double x = 0; x <= s.width; x += 4) {
        wave.lineTo(x, y + math.sin(x / 18 + row) * 4);
      }
      canvas.drawPath(
        wave,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF9FE3E8).withValues(alpha: 0.25 - row * 0.05),
      );
    }
  }

  void _cosmos(Canvas canvas, Size s, Rect rect) {
    _sky(canvas, rect, const Color(0xFF211F57), const Color(0xFF080A22));
    final math.Random rng = math.Random(7);
    final Paint star = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (int i = 0; i < 36; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height),
        rng.nextDouble() * 1.4 + 0.4,
        star,
      );
    }
    final Offset planet = Offset(s.width * 0.8, s.height * 0.55);
    canvas.drawCircle(planet, 22, Paint()..color = const Color(0xFF6C5BD6));
    canvas.drawOval(
      Rect.fromCenter(center: planet, width: 70, height: 16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD7C9FF).withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) => old.themeKey != themeKey;
}
