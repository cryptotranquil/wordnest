import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import '../models/level.dart';
import '../services/sound_service.dart';
import 'player_state.dart';
import 'stats_state.dart';

enum WordFeedback { none, invalid, duplicate }

/// Rules and state for a single level: swiping words, filling the grid,
/// spending coins on boosters and scoring the level.
class GameController extends ChangeNotifier {
  GameController({required this.level, required this.player, StatsState? stats})
      : stats = stats ?? StatsState.instance,
        _wheelOrder = List<int>.generate(level.letters.length, (i) => i);

  final Level level;
  final PlayerState player;
  final StatsState stats;

  static const int hintCost = 100;
  static const int targetCost = 150;
  static const int baseReward = 25;
  static const int lexiconReward = 50;

  final Set<String> foundWords = <String>{};
  final Set<String> foundBonus = <String>{};
  final Set<String> solvedCells = <String>{};
  final Set<String> revealedCells = <String>{};
  final Set<String> highlightedCells = <String>{};

  List<int> _wheelOrder;
  String _input = '';
  WordFeedback _feedback = WordFeedback.none;
  int _attempts = 0;
  int _accepted = 0;
  int _hintsUsed = 0;
  int _targetsUsed = 0;
  bool _awarded = false;
  int _coinsAwarded = 0;

  Timer? _feedbackTimer;
  Timer? _highlightTimer;

  /// Order in which the wheel letters are laid out (shuffling or rotating this
  /// keeps the player's remembered positions intact).
  List<int> get wheelOrder => List<int>.unmodifiable(_wheelOrder);

  List<String> get wheelLetters =>
      <String>[for (final index in _wheelOrder) level.letters[index]];

  String get input => _input;
  WordFeedback get feedback => _feedback;
  int get attempts => _attempts;
  int get accepted => _accepted;
  int get hintsUsed => _hintsUsed;
  int get targetsUsed => _targetsUsed;
  int get coinsAwarded => _coinsAwarded;

  int get solvedWordCount => foundWords.length;
  int get wordTotal => level.words.length;
  bool get isComplete => solvedWordCount == wordTotal;

  int get bonusFound => foundBonus.length;
  int get bonusTotal => level.bonusWords.length;

  double get precision => _attempts == 0 ? 1 : _accepted / _attempts;

  bool get earnedMastery => _hintsUsed == 0 && _targetsUsed == 0;
  bool get earnedLexicon => bonusTotal > 0 && bonusFound == bonusTotal;

  /// Mirrors the canvas: Speed and Mastery light up on completion, Lexicon
  /// needs every bonus word.
  bool get earnedSpeed => isComplete;

  bool get awarded => _awarded;

  /// Letters the board currently shows for a cell (solved or hint-revealed).
  String? visibleLetter(GridCell cell) {
    final key = cell.key;
    if (solvedCells.contains(key) || revealedCells.contains(key)) {
      return level.letterAt(cell);
    }
    return null;
  }

  bool isShortcutHighlighted(GridCell cell) => highlightedCells.contains(cell.key);

  bool alreadyFound(String word) =>
      foundWords.contains(word) || foundBonus.contains(word);

  /// Called by the wheel while the player is dragging.
  void setInput(String value) {
    if (_input == value) return;
    // Calculate how many letters changed
    int letterCount = 0;
    if (value.isNotEmpty) {
      letterCount = value.length;
    }
    if (letterCount > _input.length && letterCount <= 7) {
      SoundService.instance.playLetter(letterCount);
    }
    _input = value;
    notifyListeners();
  }

  /// Called when the finger lifts off the wheel.
  void submitWord(String rawWord) {
    final word = rawWord.toUpperCase();
    _input = '';
    clearHighlight();

    if (word.length < 3) {
      _attempts++;
      SoundService.instance.play(SoundId.uiTap);
      _flash(WordFeedback.invalid);
      return;
    }

    final target = level.wordFor(word);
    if (target != null && !foundWords.contains(word)) {
      foundWords.add(word);
      solvedCells.addAll(target.cells.map((c) => c.key));
      revealedCells.removeAll(target.cells.map((c) => c.key));
      _attempts++;
      _accepted++;
      _feedback = WordFeedback.none;
      SoundService.instance.play(SoundId.wordCorrect);
      notifyListeners();
      return;
    }

    if (level.bonusWords.contains(word) && !foundBonus.contains(word)) {
      foundBonus.add(word);
      stats.recordBonus();
      _attempts++;
      _accepted++;
      _feedback = WordFeedback.none;
      SoundService.instance.play(SoundId.wordBonus);
      notifyListeners();
      return;
    }

    if (alreadyFound(word)) {
      SoundService.instance.play(SoundId.wordRepeat);
      _flash(WordFeedback.duplicate);
      return;
    }

    _attempts++;
    SoundService.instance.play(SoundId.wordWrong);
    _flash(WordFeedback.invalid);
  }

  /// Reveals one letter of the next unsolved word. Returns false when the
  /// player cannot afford it. Uses free hint tokens first, then coins.
  bool revealWithHint() {
    final word = _nextUnsolvedWord();
    if (word == null) return false;

    final candidates = word.cells
        .where((c) => !solvedCells.contains(c.key) && !revealedCells.contains(c.key))
        .toList();
    if (candidates.isEmpty) return false;
    final bool usedFreeToken = player.useHintToken();
    if (!usedFreeToken && player.coins < hintCost) return false;

    revealedCells.add(candidates.first.key);
    _hintsUsed++;
    stats.recordHint();

    // Spend coin if no free token was available
    if (!usedFreeToken) {
      player.spend(hintCost);
    }

    SoundService.instance.play(SoundId.hint);
    notifyListeners();
    return true;
  }

  /// Highlights the cells of the next unsolved word for a few seconds.
  /// Returns false when the player cannot afford it. Uses free target tokens
  /// first, then coins.
  bool highlightWithTarget() {
    final word = _nextUnsolvedWord();
    if (word == null) return false;
    final bool usedFreeToken = player.useTargetToken();
    if (!usedFreeToken && player.coins < targetCost) return false;

    highlightedCells
      ..clear()
      ..addAll(word.cells.map((c) => c.key));
    _targetsUsed++;

    // Spend coin if no free token was available
    if (!usedFreeToken) {
      player.spend(targetCost);
    }

    SoundService.instance.play(SoundId.target);
    notifyListeners();

    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 4), clearHighlight);
    return true;
  }

  void clearHighlight() {
    if (highlightedCells.isEmpty) return;
    highlightedCells.clear();
    notifyListeners();
  }

  void shuffle() {
    if (_wheelOrder.length < 2) return;
    final random = math.Random();
    final oldOrder = List<int>.from(_wheelOrder);
    _wheelOrder = List<int>.from(_wheelOrder)..shuffle(random);
    // If the shuffle didn't change the order, swap first two elements
    if (ListEquality().equals(_wheelOrder, oldOrder)) {
      _wheelOrder[0] = oldOrder[1];
      _wheelOrder[1] = oldOrder[0];
    }
    SoundService.instance.play(SoundId.shuffle);
    notifyListeners();
  }

  /// Credits the level reward exactly once.
  void awardCompletion() {
    if (_awarded || !isComplete) return;
    _awarded = true;
    stats.recordCompletion(noHints: earnedMastery, flawless: precision == 1);
    _coinsAwarded = baseReward + (earnedLexicon ? lexiconReward : 0);
    player.credit(_coinsAwarded);
    SoundService.instance.play(SoundId.levelComplete);
    notifyListeners();
  }

  PlacedWord? _nextUnsolvedWord() {
    final remaining = level.words.where((w) => !foundWords.contains(w.word)).toList();
    if (remaining.isEmpty) return null;
    remaining.sort((a, b) => b.cells.length.compareTo(a.cells.length));
    return remaining.first;
  }

  void _flash(WordFeedback feedback) {
    _feedback = feedback;
    notifyListeners();
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (_feedback == WordFeedback.none) return;
      _feedback = WordFeedback.none;
      notifyListeners();
    });
  }

  /// Percentage of the level cleared, used by the home screen progress bar.
  double get progress => wordTotal == 0 ? 0 : solvedWordCount / wordTotal;

  /// Longest word still unsolved, handy for the string capsule placeholder.
  int get longestWordLength =>
      level.words.map((w) => w.word.length).fold(0, math.max);

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }
}
