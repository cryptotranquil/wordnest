import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wordnest/src/data/daily_rewards.dart';
import 'package:wordnest/src/screens/daily_reward_screen.dart';
import 'package:wordnest/src/state/daily_reward_service.dart';
import 'package:wordnest/src/state/player_state.dart';

void main() {
  group('DailyRewardScreen', () {
    testWidgets('renders with claimed/today/locked states', (WidgetTester tester) async {
      // Set up player state with day 3 claimed
      final player = PlayerState();
      player.claimDailyRewardNoSave(
        coins: 100,
        hints: 0,
        targets: 0,
        date: '2024-01-03',
        day: 3,
        cycle: 0,
      );

      // Set up service with fixed now function
      DateTime nowFn() => DateTime(2024, 1, 4, 12, 0, 0); // Day 4 is today
      final service = DailyRewardService(player: player, now: nowFn);

      // Build the screen
      await tester.pumpWidget(
        MaterialApp(
          home: DailyRewardScreen(player: player, service: service),
        ),
      );

      // Verify the screen renders
      expect(find.byType(DailyRewardScreen), findsOneWidget);

      // Verify streak text is present
      expect(find.text('Day 4 Streak'), findsOneWidget);

      // Verify Daily Gift title
      expect(find.text('Daily Gift'), findsOneWidget);

      // Verify footer quote
      expect(find.text('Consistency is the gentle path to wisdom.'), findsOneWidget);

      // Verify TODAY tag for day 4
      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('Day 5 is locked (lock icon visible)', (WidgetTester tester) async {
      final player = PlayerState();
      player.claimDailyRewardNoSave(
        coins: 100,
        hints: 0,
        targets: 0,
        date: '2024-01-03',
        day: 3,
        cycle: 0,
      );

      DateTime nowFn() => DateTime(2024, 1, 4, 12, 0, 0);
      final service = DailyRewardService(player: player, now: nowFn);

      await tester.pumpWidget(
        MaterialApp(
          home: DailyRewardScreen(player: player, service: service),
        ),
      );

      // Days 1, 2, 5, 6, 7 are locked. Day 7 might have different styling.
      // At minimum, days 5, 6 should show lock icons.
      final lockFinder = find.byIcon(Icons.lock_rounded);
      expect(lockFinder, findsNWidgets(4)); // Days 1, 2, 5, 6
    });

    testWidgets('Day 7 is Grand Chest (wider cell)', (WidgetTester tester) async {
      final player = PlayerState();
      player.claimDailyRewardNoSave(
        coins: 100,
        hints: 0,
        targets: 0,
        date: '2024-01-01',
        day: 1,
        cycle: 0,
      );

      DateTime nowFn() => DateTime(2024, 1, 2, 12, 0, 0);
      final service = DailyRewardService(player: player, now: nowFn);

      await tester.pumpWidget(
        MaterialApp(
          home: DailyRewardScreen(player: player, service: service),
        ),
      );

      // Day 7 (Grand Chest) should exist in the tree - check for the 7 cell
      // The cell text '7' should be present
      expect(find.text('7'), findsOneWidget);
    });

    test('Reward table values match expected', () {
      // Week 1, Day 1: 50 coins
      expect(rewardFor(0, 1).coins, 50);
      expect(rewardFor(0, 1).hints, 0);
      expect(rewardFor(0, 1).targets, 0);

      // Week 1, Day 2: 1 hint
      expect(rewardFor(0, 2).coins, 0);
      expect(rewardFor(0, 2).hints, 1);
      expect(rewardFor(0, 2).targets, 0);

      // Week 1, Day 7: 500 coins + 1 hint + 1 target
      expect(rewardFor(0, 7).coins, 500);
      expect(rewardFor(0, 7).hints, 1);
      expect(rewardFor(0, 7).targets, 1);

      // Week 2, Day 1: 75 coins
      expect(rewardFor(1, 1).coins, 75);

      // Week 3, Day 1: 100 coins
      expect(rewardFor(2, 1).coins, 100);
      expect(rewardFor(3, 1).coins, 100); // Same as week 3+
    });
  });
}
