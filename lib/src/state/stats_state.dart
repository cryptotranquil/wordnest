import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lifetime totals and separate local-day counters for missions.
class StatsState extends ChangeNotifier {
  StatsState({DateTime Function()? now}) : _now = now ?? DateTime.now;
  static final StatsState instance = StatsState();
  static const _key = 'stats_snapshot_v2';
  final DateTime Function() _now;
  Future<void> _pendingSave = Future.value();
  String _day = '';
  int bonusWordsFound = 0;
  int levelsCleared = 0;
  int levelsWithoutHints = 0;
  int flawlessLevels = 0;
  int hintsUsed = 0;
  int dailyBonus = 0;
  int dailyLevels = 0;
  int dailyNoHints = 0;
  int dailySeconds = 0;

  String get today {
    final date = _now();
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get isCurrentDay => today == _day;
  int dailyProgress(String id) {
    if (!isCurrentDay) return 0;
    return switch (id) {
      'bonus' => dailyBonus,
      'levels' => dailyLevels,
      'time' => dailySeconds,
      'no_hints' => dailyNoHints,
      _ => 0,
    };
  }

  Duration get timeUntilReset {
    final date = _now();
    return DateTime(date.year, date.month, date.day + 1).difference(date);
  }

  void refreshDay() {
    final day = today;
    if (_day.isEmpty || day.compareTo(_day) > 0) {
      _day = day;
      dailyBonus = dailyLevels = dailyNoHints = dailySeconds = 0;
      save();
      notifyListeners();
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      _day = d['day'] as String? ?? '';
      bonusWordsFound = d['bonus'] as int? ?? 0;
      levelsCleared = d['levels'] as int? ?? 0;
      levelsWithoutHints = d['noHints'] as int? ?? 0;
      flawlessLevels = d['flawless'] as int? ?? 0;
      hintsUsed = d['hints'] as int? ?? 0;
      dailyBonus = d['dailyBonus'] as int? ?? 0;
      dailyLevels = d['dailyLevels'] as int? ?? 0;
      dailyNoHints = d['dailyNoHints'] as int? ?? 0;
      dailySeconds = d['dailySeconds'] as int? ?? 0;
    } else {
      // Preserve any lifetime totals written by the old, unused StatsState.
      bonusWordsFound = prefs.getInt('bonusWordsFound') ?? 0;
      levelsCleared = prefs.getInt('levelsCleared') ?? 0;
      levelsWithoutHints = prefs.getInt('levelsWithoutHints') ?? 0;
      flawlessLevels = prefs.getInt('flawlessLevels') ?? 0;
      hintsUsed = prefs.getInt('hintsUsed') ?? 0;
    }
    refreshDay();
    notifyListeners();
  }

  Future<void> save() {
    final snapshot = jsonEncode({
      'day': _day, 'bonus': bonusWordsFound, 'levels': levelsCleared,
      'noHints': levelsWithoutHints, 'flawless': flawlessLevels, 'hints': hintsUsed,
      'dailyBonus': dailyBonus, 'dailyLevels': dailyLevels,
      'dailyNoHints': dailyNoHints, 'dailySeconds': dailySeconds,
    });
    _pendingSave = _pendingSave.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, snapshot);
    });
    return _pendingSave;
  }

  void recordBonus() {
    refreshDay();
    bonusWordsFound++;
    if (today == _day) dailyBonus++;
    save();
    notifyListeners();
  }

  void recordCompletion({required bool noHints, required bool flawless}) {
    refreshDay();
    levelsCleared++;
    if (today == _day) dailyLevels++;
    if (noHints) {
      levelsWithoutHints++;
      if (today == _day) dailyNoHints++;
    }
    if (flawless) flawlessLevels++;
    save();
    notifyListeners();
  }

  void recordHint() { hintsUsed++; save(); notifyListeners(); }

  void recordPlaySeconds(int seconds) {
    if (seconds <= 0) return;
    refreshDay();
    if (today == _day) dailySeconds += seconds;
    save();
    notifyListeners();
  }
}
