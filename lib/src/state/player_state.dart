import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_service.dart';

class PlayerState extends ChangeNotifier {
  static const String _coinsKey = 'coins';
  static const String _hintsKey = 'hints';
  static const String _targetsKey = 'targets';
  static const String _currentLevelKey = 'currentLevel';
  static const String _claimedDayKey = 'claimedDay';
  static const String _claimedCycleKey = 'claimedCycle';
  static const String _lastClaimDateKey = 'lastClaimDate';
  static const String _currentChapterKey = 'currentChapter';
  static const String _tutorialSeenKey = 'tutorialSeen';
  static const String _removeAdsKey = 'removeAdsOwned';

  int _coins = 0;
  int _hints = 0;
  int _targets = 0;
  int _currentLevel = 1;
  int _claimedDay = 0;
  int _claimedCycle = 0;
  String? _lastClaimDate;
  int _currentChapter = 1;
  bool _tutorialSeen = false;
  bool _removeAdsOwned = false;

  int get coins => _coins;
  int get hints => _hints;
  int get targets => _targets;
  int get hintTokens => _hints;
  int get targetTokens => _targets;
  int get currentLevel => _currentLevel;
  int get claimedDay => _claimedDay;
  int get claimedCycle => _claimedCycle;
  int get cycleCount => _claimedCycle;
  String? get lastClaimDate => _lastClaimDate;
  int get currentChapter => _currentChapter;
  bool get tutorialSeen => _tutorialSeen;
  bool get removeAdsOwned => _removeAdsOwned;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(_coinsKey) ?? 0;
    _hints = prefs.getInt(_hintsKey) ?? 0;
    _targets = prefs.getInt(_targetsKey) ?? 0;
    _currentLevel = prefs.getInt(_currentLevelKey) ?? 1;
    _claimedDay = prefs.getInt(_claimedDayKey) ?? 0;
    _claimedCycle = prefs.getInt(_claimedCycleKey) ?? 0;
    _lastClaimDate = prefs.getString(_lastClaimDateKey);
    _currentChapter = prefs.getInt(_currentChapterKey) ?? 1;
    _tutorialSeen = prefs.getBool(_tutorialSeenKey) ?? false;
    _removeAdsOwned = prefs.getBool(_removeAdsKey) ?? false;
    AdService().setRemoveAdsOwned(_removeAdsOwned);
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, _coins);
    await prefs.setInt(_hintsKey, _hints);
    await prefs.setInt(_targetsKey, _targets);
    await prefs.setInt(_currentLevelKey, _currentLevel);
    await prefs.setInt(_claimedDayKey, _claimedDay);
    await prefs.setInt(_claimedCycleKey, _claimedCycle);
    if (_lastClaimDate != null) {
      await prefs.setString(_lastClaimDateKey, _lastClaimDate!);
    }
    await prefs.setInt(_currentChapterKey, _currentChapter);
    await prefs.setBool(_tutorialSeenKey, _tutorialSeen);
    await prefs.setBool(_removeAdsKey, _removeAdsOwned);
  }

  void setCurrentChapter(int chapter) {
    _currentChapter = chapter;
    save();
    notifyListeners();
  }

  void setCurrentLevel(int level) {
    _currentLevel = level;
    if (_currentChapter < 1) {
      _currentChapter = 1;
    }
    save();
    notifyListeners();
  }

  void markTutorialSeen() {
    _tutorialSeen = true;
    save();
    notifyListeners();
  }

  void spend(int amount) {
    if (_coins < amount) return;
    _coins -= amount;
    save();
    notifyListeners();
  }

  void credit(int amount) {
    _coins += amount;
    save();
    notifyListeners();
  }

  void addCoins(int amount) => credit(amount);

  void setRemoveAds(bool owned) {
    _removeAdsOwned = owned;
    AdService().setRemoveAdsOwned(owned);
    save();
    notifyListeners();
  }

  bool useHintToken() {
    if (_hints <= 0) return false;
    _hints -= 1;
    save();
    notifyListeners();
    return true;
  }

  bool useTargetToken() {
    if (_targets <= 0) return false;
    _targets -= 1;
    save();
    notifyListeners();
    return true;
  }

  void claimDailyRewardNoSave({
    required int coins,
    required int hints,
    required int targets,
    required String date,
    required int day,
    required int cycle,
  }) {
    _coins += coins;
    _hints += hints;
    _targets += targets;
    _lastClaimDate = date;
    _claimedDay = day;
    _claimedCycle = cycle;
    notifyListeners();
  }

  void addHints(int amount) {
    _hints += amount;
    save();
    notifyListeners();
  }
}