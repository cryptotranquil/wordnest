import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsState extends ChangeNotifier {
  static const String _bonusWordsFoundKey = 'bonusWordsFound';
  static const String _levelsClearedKey = 'levelsCleared';
  static const String _levelsWithoutHintsKey = 'levelsWithoutHints';
  static const String _flawlessLevelsKey = 'flawlessLevels';
  static const String _hintsUsedKey = 'hintsUsed';

  int _bonusWordsFound = 0;
  int _levelsCleared = 0;
  int _levelsWithoutHints = 0;
  int _flawlessLevels = 0;
  int _hintsUsed = 0;

  int get bonusWordsFound => _bonusWordsFound;
  int get levelsCleared => _levelsCleared;
  int get levelsWithoutHints => _levelsWithoutHints;
  int get flawlessLevels => _flawlessLevels;
  int get hintsUsed => _hintsUsed;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _bonusWordsFound = prefs.getInt(_bonusWordsFoundKey) ?? 0;
    _levelsCleared = prefs.getInt(_levelsClearedKey) ?? 0;
    _levelsWithoutHints = prefs.getInt(_levelsWithoutHintsKey) ?? 0;
    _flawlessLevels = prefs.getInt(_flawlessLevelsKey) ?? 0;
    _hintsUsed = prefs.getInt(_hintsUsedKey) ?? 0;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bonusWordsFoundKey, _bonusWordsFound);
    await prefs.setInt(_levelsClearedKey, _levelsCleared);
    await prefs.setInt(_levelsWithoutHintsKey, _levelsWithoutHints);
    await prefs.setInt(_flawlessLevelsKey, _flawlessLevels);
    await prefs.setInt(_hintsUsedKey, _hintsUsed);
  }

  void incrementBonusWordsFound() {
    _bonusWordsFound++;
    save();
    notifyListeners();
  }

  void incrementLevelsCleared() {
    _levelsCleared++;
    save();
    notifyListeners();
  }

  void incrementLevelsWithoutHints() {
    _levelsWithoutHints++;
    save();
    notifyListeners();
  }

  void incrementFlawlessLevels() {
    _flawlessLevels++;
    save();
    notifyListeners();
  }

  void incrementHintsUsed() {
    _hintsUsed++;
    save();
    notifyListeners();
  }

  void resetDailyStats() {
    _bonusWordsFound = 0;
    _levelsCleared = 0;
    _levelsWithoutHints = 0;
    save();
    notifyListeners();
  }
}