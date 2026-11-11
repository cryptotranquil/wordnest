import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/levels.dart';
import '../models/level.dart';
import '../state/game_controller.dart';
import '../state/player_state.dart';
import '../theme/wordnest_theme.dart';
import '../widgets/board.dart';
import '../widgets/capsules.dart';
import '../widgets/controls.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/scenic_background.dart';
import 'level_complete_sheet.dart';
import 'shop_screen.dart';
import 'tutorial_overlay.dart';

/// The playable level: crossword, bonus progress, swipe wheel and boosters.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({
    super.key,
    required this.level,
    required this.player,
  });

  final Level level;
  final PlayerState player;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late final GameController _game;
  final GlobalKey _wheelKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _bonusKey = GlobalKey();
  final GlobalKey _coinKey = GlobalKey();

  bool _sheetShown = false;
  bool _tutorialActive = false;
  int _tutorialStep = 0;
  List<Rect>? _tutorialRects;

  static const List<TutorialStep> _steps = <TutorialStep>[
    TutorialStep(
      title: 'Swipe to connect',
      body: 'Drag from one letter to the next to build a word. Any order, any direction.',
      circular: true,
    ),
    TutorialStep(
      title: 'Fill the grid',
      body: 'A word that belongs in the crossword drops straight into the board. '
          'Entries cross each other, so one word can open two.',
    ),
    TutorialStep(
      title: 'Bonus words',
      body: 'Words that are not in the grid still count. Every one you find fills the bonus jar.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _game = GameController(level: widget.level, player: widget.player);
    _tutorialActive = !widget.player.tutorialSeen;
    if (_tutorialActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureTargets());
    }
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- tutorial

  void _captureTargets() {
    if (!mounted || !_tutorialActive) return;
    final screenBox = context.findRenderObject() as RenderBox?;
    if (screenBox == null || !screenBox.hasSize) return;

    Rect rectOf(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return Rect.zero;
      return box.localToGlobal(Offset.zero, ancestor: screenBox) & box.size;
    }

    final rects = <Rect>[rectOf(_wheelKey), rectOf(_boardKey), rectOf(_bonusKey)];
    if (rects.any((r) => r.isEmpty)) {
      // Layout was not ready; skip the overlay rather than pointing at nothing.
      setState(() => _tutorialActive = false);
      widget.player.markTutorialSeen();
      return;
    }
    setState(() => _tutorialRects = rects);
  }

  void _advanceTutorial() {
    if (_tutorialStep >= _steps.length - 1) {
      _endTutorial();
      return;
    }
    setState(() => _tutorialStep++);
  }

  void _endTutorial() {
    widget.player.markTutorialSeen();
    setState(() => _tutorialActive = false);
  }

  // ------------------------------------------------------------------ rules

  void _submit(String word) {
    _game.submitWord(word);
    if (_game.feedback == WordFeedback.invalid) {
      HapticFeedback.mediumImpact();
    }
    if (_game.isComplete) _completeLevel();
  }

  void _completeLevel() {
    if (_sheetShown) return;
    _sheetShown = true;
    _game.awardCompletion();
    final next = LevelBook.nextLevelAfter(widget.level.number);
    // Replaying an earlier puzzle must not send the player backwards.
    if (next != null && widget.level.number == widget.player.currentLevel) {
      widget.player.setCurrentLevel(next);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCompleteSheet());
  }

  void _openCompleteSheet() {
    if (!mounted) return;
    final next = LevelBook.nextLevelAfter(widget.level.number);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.inkDeep.withValues(alpha: 0.55),
      builder: (BuildContext sheetContext) => LevelCompleteSheet(
        controller: _game,
        hasNext: next != null,
        onClose: () => Navigator.of(sheetContext).pop(),
        onReplay: () {
          Navigator.of(sheetContext).pop();
          _restart();
        },
        onNext: () {
          Navigator.of(sheetContext).pop();
          if (next == null) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => GameplayScreen(
                level: LevelBook.level(next),
                player: widget.player,
              ),
            ),
          );
        },
      ),
    );
  }

  void _restart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(level: widget.level, player: widget.player),
      ),
    );
  }

  void _hint() {
    if (_game.isComplete) return;
    final ok = _game.revealWithHint();
    if (!ok) {
      _toast('Hints cost ${GameController.hintCost} coins.');
    }
  }

  void _target() {
    if (_game.isComplete) return;
    final ok = _game.highlightWithTarget();
    if (!ok) {
      _toast('Target costs ${GameController.targetCost} coins.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showBonusWords() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.inkDeep.withValues(alpha: 0.5),
      builder: (BuildContext sheetContext) {
        final found = _game.foundBonus.toList()..sort();
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppMetrics.sheetRadius),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xE610262A), Color(0xF708181C)],
            ),
            border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Bonus words',
                      style: AppText.quicksand(20, color: AppColors.cream),
                    ),
                    Text(
                      '${_game.bonusFound} / ${_game.bonusTotal}',
                      style: AppText.label(12, weight: 700, color: AppColors.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (found.isEmpty)
                  Text(
                    'No bonus words found yet. Every accepted extra word lands here.',
                    style: AppText.label(12.5, weight: 500, color: AppColors.muted, height: 1.5),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final word in found)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[AppColors.creamTop, AppColors.creamBottom],
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: AppColors.bevel,
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            word,
                            style: AppText.quicksand(14, color: AppColors.tileInk),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 18),
                SecondaryButton(
                  label: 'Close',
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ScenicBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_game, widget.player]),
              builder: (BuildContext context, _) {
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final metrics = _BoardMetrics.fit(
                      constraints: constraints,
                      level: widget.level,
                    );

                    return Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              LevelPill(
                                level: widget.level.number,
                                onBack: () => Navigator.of(context).maybePop(),
                              ),
                              CoinPill(
                                key: _coinKey,
                                coins: widget.player.coins,
                                onAdd: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ShopScreen(player: widget.player),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                KeyedSubtree(
                                  key: _boardKey,
                                  child: WordGrid(
                                    controller: _game,
                                    cellSize: metrics.cell,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                KeyedSubtree(
                                  key: _bonusKey,
                                  child: BonusPill(
                                    found: _game.bonusFound,
                                    total: _game.bonusTotal,
                                    onTap: _showBonusWords,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                StringPill(
                                  input: _game.input,
                                  feedback: _game.feedback,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              BoosterButton(
                                icon: Icons.lightbulb_outline_rounded,
                                label: 'Hint',
                                cost: GameController.hintCost,
                                tokenCount: widget.player.hintTokens,
                                onTap: _hint,
                              ),
                              LetterWheel(
                                key: _wheelKey,
                                letters: _game.wheelLetters,
                                size: metrics.wheel,
                                onChanged: _game.setInput,
                                onSubmit: _submit,
                                onShuffle: _game.shuffle,
                              ),
                              BoosterButton(
                                icon: Icons.center_focus_strong_rounded,
                                label: 'Target',
                                cost: GameController.targetCost,
                                tokenCount: widget.player.targetTokens,
                                onTap: _target,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_tutorialActive && _tutorialRects != null)
            Positioned.fill(
              child: TutorialOverlay(
                steps: _steps,
                targets: _tutorialRects!,
                index: _tutorialStep,
                onNext: _advanceTutorial,
                onSkip: _endTutorial,
              ),
            ),
        ],
      ),
    );
  }
}

/// Board and wheel sizes derived from the space actually available, so the
/// screen keeps the canvas proportions on any phone.
class _BoardMetrics {
  const _BoardMetrics({required this.cell, required this.wheel});

  final double cell;
  final double wheel;

  factory _BoardMetrics.fit({
    required BoxConstraints constraints,
    required Level level,
  }) {
    const header = 52.0;
    const reservedPills = 13 + AppMetrics.smallPillHeight + 13 + AppMetrics.pillHeight;
    const gap = AppMetrics.gridGap;

    final wheel = math.min(
      AppMetrics.wheelSize,
      constraints.maxWidth - 32 - 2 * (AppMetrics.boosterSize + 8),
    );

    final boardHeight = constraints.maxHeight - header - wheel - 46;
    final cellFromWidth =
        (constraints.maxWidth - 32 - (level.cols - 1) * gap) / level.cols;
    final cellFromHeight =
        (boardHeight - reservedPills - (level.rows - 1) * gap) / level.rows;

    final cell = math
        .min(math.min(cellFromWidth, cellFromHeight), 58.0)
        .clamp(24.0, 58.0)
        .toDouble();

    return _BoardMetrics(cell: cell, wheel: wheel);
  }
}
