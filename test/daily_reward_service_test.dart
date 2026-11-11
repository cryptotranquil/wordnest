import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wordnest/src/data/daily_rewards.dart';
import 'package:wordnest/src/state/daily_reward_service.dart';
import 'package:wordnest/src/state/player_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  group('DailyRewardService', () {
    /// Create a service with a fixed now function.
    DailyRewardService makeService(DateTime fixedNow, {PlayerState? player}) {
      final p = player ?? PlayerState();
      return DailyRewardService(player: p, now: () => fixedNow);
    }

    test('first claim - day 1, cycle 0', () {
      final service = makeService(DateTime(2024, 1, 1, 12, 0, 0));
      final reward = service.claim();

      expect(reward, isNotNull);
      expect(reward!.coins, 50);
      expect(reward.hints, 0);
      expect(reward.targets, 0);

      expect(service.player.lastClaimDate, '2024-01-01');
      expect(service.player.claimedDay, 1);
      expect(service.player.cycleCount, 0);
      expect(service.player.coins, 50);
    });

    test('consecutive days - streak continues correctly', () {
      // Day 1
      final player1 = PlayerState();
      final service1 = makeService(DateTime(2024, 1, 1, 12, 0, 0), player: player1);
      final reward1 = service1.claim();
      expect(reward1!.coins, 50);

      // Day 2 - next day with same player state
      final service2 = makeService(DateTime(2024, 1, 2, 12, 0, 0), player: player1);
      final reward2 = service2.claim();
      expect(reward2!.coins, 0);
      expect(reward2.hints, 1);
      expect(service2.player.claimedDay, 2);
      expect(service2.player.cycleCount, 0);
    });

    test('day 7 -> day 1 with cycle+1', () {
      final player = PlayerState();

      // Claim days 1-6 first
      for (int d = 1; d <= 6; d++) {
        final service = makeService(DateTime(2024, 1, d, 12, 0, 0), player: player);
        service.claim();
      }

      // Day 7 (cycle 0)
      final service1 = makeService(DateTime(2024, 1, 7, 12, 0, 0), player: player);
      final reward1 = service1.claim();
      expect(reward1!.coins, 500);
      expect(reward1.hints, 1);
      expect(reward1.targets, 1);
      expect(player.claimedDay, 7);
      expect(player.cycleCount, 0);

      // Day 1 next week (cycle 1)
      final service2 = makeService(DateTime(2024, 1, 8, 12, 0, 0), player: player);
      final reward2 = service2.claim();
      expect(reward2!.coins, 75);
      expect(reward2.hints, 0);
      expect(reward2.targets, 0);
      expect(player.claimedDay, 1);
      expect(player.cycleCount, 1);
    });

    test('missed day reset - streak resets to day 1', () {
      final player = PlayerState();

      // Claim day 2
      final service1 = makeService(DateTime(2024, 1, 2, 12, 0, 0), player: player);
      service1.claim();

      // Miss days 3-4, now claim on day 5 (should reset to day 1)
      // Since the streak resets to day 1 and cycle stays the same (0), we get week 1 day 1 rewards
      final service2 = makeService(DateTime(2024, 1, 5, 12, 0, 0), player: player);
      final reward = service2.claim();

      // Should reset to day 1 with cycle 0 (week 1)
      expect(reward!.coins, 50);
      expect(reward.hints, 0);
      expect(reward.targets, 0);
      expect(player.claimedDay, 1);
      expect(player.cycleCount, 0);
    });

    test('double claim same day returns null', () {
      final player = PlayerState();
      final service1 = makeService(DateTime(2024, 1, 1, 12, 0, 0), player: player);
      final reward1 = service1.claim();
      expect(reward1, isNotNull);

      // Second claim on same day should return null
      final service2 = makeService(DateTime(2024, 1, 1, 15, 0, 0), player: player);
      final reward2 = service2.claim();
      expect(reward2, isNull);
    });

    test('clock set backwards - cannot claim', () {
      final player = PlayerState();
      // Last claim was on 2024-01-05
      final service1 = makeService(DateTime(2024, 1, 5, 12, 0, 0), player: player);
      service1.claim();

      // Today is set to 2024-01-03 (before last claim)
      final service2 = makeService(DateTime(2024, 1, 3, 12, 0, 0), player: player);

      expect(service2.canClaimToday, isFalse);
      expect(service2.claim(), isNull);
    });

    test('timeUntilReset - returns time until midnight', () {
      final service = makeService(DateTime(2024, 1, 1, 14, 30, 0));
      final duration = service.timeUntilReset;

      // Should be 9.5 hours until midnight
      expect(duration.inHours, 9);
      expect(duration.inMinutes, 570); // 9.5 hours = 570 minutes
    });

    test('canClaimToday - never claimed returns true', () {
      final player = PlayerState();
      final service = makeService(DateTime(2024, 1, 1, 12, 0, 0), player: player);
      expect(service.canClaimToday, isTrue);
    });

    test('canClaimToday - same day returns false', () {
      final player = PlayerState();
      // Set player state to have claimed today
      player.claimDailyRewardNoSave(
        coins: 50,
        hints: 0,
        targets: 0,
        date: '2024-01-01',
        day: 1,
        cycle: 0,
      );

      final service = makeService(DateTime(2024, 1, 1, 12, 0, 0), player: player);
      expect(service.canClaimToday, isFalse);
    });
  });

  group('DailyReward equality', () {
    test('two rewards with same values are equal', () {
      final r1 = DailyReward(coins: 100, hints: 2, targets: 1);
      final r2 = DailyReward(coins: 100, hints: 2, targets: 1);

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('two rewards with different values are not equal', () {
      final r1 = DailyReward(coins: 100, hints: 2, targets: 1);
      final r2 = DailyReward(coins: 100, hints: 2, targets: 0);

      expect(r1, isNot(equals(r2)));
    });
  });

  group('clampCycle', () {
    test('negative cycle clamps to 0', () {
      expect(clampCycle(-1), equals(0));
      expect(clampCycle(-10), equals(0));
    });

    test('cycle 0 stays 0', () {
      expect(clampCycle(0), equals(0));
    });

    test('cycle 1 stays 1', () {
      expect(clampCycle(1), equals(1));
    });

    test('cycle 2+ clamps to 2', () {
      expect(clampCycle(2), equals(2));
      expect(clampCycle(3), equals(2));
      expect(clampCycle(100), equals(2));
    });
  });
}
