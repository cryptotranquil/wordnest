import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_service.dart';

class PlayerState extends ChangeNotifier {
  static const String _snapshotKey = 'player_snapshot_v2';
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
  bool _finishedJourney = false;
  String _missionDay = '';
  Set<String> _dailyClaims = {};
  Map<String, int> _achievementClaims = {};
  Future<void> _pendingSave = Future.value();

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
  bool get finishedJourney => _finishedJourney;

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
    final snapshot = prefs.getString(_snapshotKey);
    if (snapshot != null) {
      final data = jsonDecode(snapshot) as Map<String, dynamic>;
      _coins = data['coins'] as int? ?? _coins;
      _hints = data['hints'] as int? ?? _hints;
      _targets = data['targets'] as int? ?? _targets;
      _currentLevel = data['currentLevel'] as int? ?? _currentLevel;
      _claimedDay = data['claimedDay'] as int? ?? _claimedDay;
      _claimedCycle = data['claimedCycle'] as int? ?? _claimedCycle;
      _lastClaimDate = data['lastClaimDate'] as String?;
      _currentChapter = data['currentChapter'] as int? ?? _currentChapter;
      _tutorialSeen = data['tutorialSeen'] as bool? ?? _tutorialSeen;
      _removeAdsOwned = data['removeAdsOwned'] as bool? ?? _removeAdsOwned;
      _finishedJourney = data['finishedJourney'] as bool? ?? false;
      _missionDay = data['missionDay'] as String? ?? '';
      _dailyClaims = Set<String>.from(data['dailyClaims'] as List? ?? []);
      _achievementClaims = Map<String, int>.from(data['achievementClaims'] as Map? ?? {});
    }
    AdService().setRemoveAdsOwned(_removeAdsOwned);
    notifyListeners();
  }

  /// One snapshot stores both the balance and claim receipts. Writes are
  /// serialized so a slower earlier save cannot overwrite a newer one.
  Future<void> save() {
    final snapshot = jsonEncode({
      'coins': _coins, 'hints': _hints, 'targets': _targets,
      'currentLevel': _currentLevel, 'claimedDay': _claimedDay,
      'claimedCycle': _claimedCycle, 'lastClaimDate': _lastClaimDate,
      'currentChapter': _currentChapter, 'tutorialSeen': _tutorialSeen,
      'removeAdsOwned': _removeAdsOwned, 'finishedJourney': _finishedJourney, 'missionDay': _missionDay,
      'dailyClaims': _dailyClaims.toList(), 'achievementClaims': _achievementClaims,
    });
    _pendingSave = _pendingSave.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_snapshotKey, snapshot);
    });
    return _pendingSave;
  }

  bool dailyClaimed(String day, String id) =>
      day == _missionDay && _dailyClaims.contains(id);
  int achievementTierClaimed(String id) => _achievementClaims[id] ?? 0;

  bool claimDailyMission(String day, String id, int coins) {
    // A clock moving backwards must not reopen an earlier reward day.
    if (day.compareTo(_missionDay) < 0) return false;
    if (day != _missionDay) {
      _missionDay = day;
      _dailyClaims = {};
    }
    if (!_dailyClaims.add(id)) return false;
    _coins += coins;
    save();
    notifyListeners();
    return true;
  }

  bool claimAchievement(String id, int tier, int coins) {
    if (tier != achievementTierClaimed(id) + 1) return false;
    _achievementClaims[id] = tier;
    _coins += coins;
    save();
    notifyListeners();
    return true;
  }

  void setCurrentChapter(int chapter) {
    _currentChapter = chapter;
    save();
    notifyListeners();
  }

  void setCurrentLevel(int level) {
    _currentLevel = level;
    _currentChapter = ((level - 1) ~/ 20) + 1;
    save();
    notifyListeners();
  }

  void markJourneyFinished() {
    if (_finishedJourney) return;
    _finishedJourney = true;
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