import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordnest/src/data/levels.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/state/stats_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('generated levels are sequential and missing levels are rejected', () {
    expect(LevelBook.all.length, 60);
    expect(LevelBook.nextLevelAfter(1), 2);
    expect(LevelBook.nextLevelAfter(60), isNull);
    expect(() => LevelBook.level(61), throwsRangeError);
  });

  test('daily stats reset without erasing lifetime stats', () async {
    var date = DateTime(2026, 1, 1, 23, 59);
    final stats = StatsState(now: () => date);
    await stats.load();
    stats.recordBonus();
    stats.recordCompletion(noHints: true, flawless: true);
    stats.recordPlaySeconds(600);
    await stats.save();
    expect(stats.dailyProgress('bonus'), 1);
    expect(stats.dailyProgress('levels'), 1);
    expect(stats.dailyProgress('no_hints'), 1);
    expect(stats.dailyProgress('time'), 600);
    date = DateTime(2026, 1, 2);
    stats.refreshDay();
    expect(stats.dailyProgress('bonus'), 0);
    expect(stats.bonusWordsFound, 1);
    expect(stats.flawlessLevels, 1);
    await stats.save();
    final restored = StatsState(now: () => date);
    await restored.load();
    expect(restored.bonusWordsFound, 1);
    expect(restored.dailyProgress('levels'), 0);
  });

  test('claim receipt and coins survive reload and cannot be claimed twice', () async {
    final player = PlayerState();
    expect(player.claimDailyMission('2026-01-01', 'bonus', 50), isTrue);
    expect(player.claimDailyMission('2026-01-01', 'bonus', 50), isFalse);
    expect(player.claimAchievement('lexicon', 1, 100), isTrue);
    expect(player.claimAchievement('lexicon', 1, 100), isFalse);
    await player.save();
    final restored = PlayerState();
    await restored.load();
    expect(restored.coins, 150);
    expect(restored.dailyClaimed('2026-01-01', 'bonus'), isTrue);
    expect(restored.achievementTierClaimed('lexicon'), 1);
    expect(restored.claimDailyMission('2025-12-31', 'bonus', 50), isFalse);
    expect(restored.claimDailyMission('2026-01-02', 'bonus', 50), isTrue);
    await restored.save();
  });

  test('legacy player preferences migrate on the next save', () async {
    SharedPreferences.setMockInitialValues({'coins': 42, 'currentLevel': 14});
    final player = PlayerState();
    await player.load();
    expect(player.coins, 42);
    expect(player.currentLevel, 14);
    await player.save();
    final restored = PlayerState();
    await restored.load();
    expect(restored.coins, 42);
    expect(restored.currentLevel, 14);
  });
}
