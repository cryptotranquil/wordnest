import '../data/daily_rewards.dart';
import 'player_state.dart';

/// Flag to control whether the streak resets when a day is missed.
/// If true: streak resets to day 1, but cycle tier stays (rewards don't shrink).
/// If false: always continue to the next day regardless of missed days.
const bool kResetStreakOnMiss = true;

/// Service to manage daily reward claiming.
///
/// Takes PlayerState and an injectable DateTime Function() for testing.
class DailyRewardService {
  DailyRewardService({
    required this.player,
    required this.now,
  });

  final PlayerState player;
  final DateTime Function() now;

  /// Get the current date as 'yyyy-MM-dd' string in local time.
  String _getDateAsString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse a 'yyyy-MM-dd' string to DateTime.
  DateTime _parseDate(String dateString) {
    final parts = dateString.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// Get today's date as a string.
  String _todayString() => _getDateAsString(now());

  /// Calculate time until next local midnight.
  Duration get timeUntilReset {
    final now = this.now();
    final todayMidnight = DateTime(now.year, now.month, now.day + 1);
    return todayMidnight.difference(now);
  }

  /// Check if today's reward can be claimed.
  ///
  /// Returns false if:
  /// - lastClaimDate == today (already claimed today)
  /// - today is BEFORE lastClaimDate (device clock set back)
  bool get canClaimToday {
    if (player.lastClaimDate == null) return true;
    final lastClaim = _parseDate(player.lastClaimDate!);
    final today = now();
    final todayStr = _getDateAsString(today);
    return player.lastClaimDate != todayStr &&
        !today.isBefore(lastClaim);
  }

  /// Determine which day should be claimed based on streak logic.
  ///
  /// - If never claimed -> day 1
  /// - If lastClaimDate was yesterday -> (claimedDay % 7) + 1
  /// - If missed more than one day:
  ///   - If kResetStreakOnMiss: reset to day 1
  ///   - Otherwise: continue to next day
  int get dayToClaim {
    if (player.lastClaimDate == null) return 1;

    final lastClaim = _parseDate(player.lastClaimDate!);
    final today = now();
    final daysSinceLastClaim = today.difference(lastClaim).inDays;

    if (daysSinceLastClaim == 1) {
      // Consecutive day
      return (player.claimedDay % 7) + 1;
    } else if (daysSinceLastClaim > 1) {
      // Missed days
      if (kResetStreakOnMiss) {
        return 1; // Reset streak
      } else {
        return (player.claimedDay % 7) + 1; // Continue to next day
      }
    }

    // daysSinceLastClaim == 0 means today was already claimed
    return player.claimedDay;
  }

  /// Determine the cycle to claim.
  ///
  /// Returns current cycleCount, incremented by 1 if:
  /// - previous claimedDay was 7 AND (streak continues OR resets on miss)
  int get cycleToClaim {
    if (player.lastClaimDate == null) return player.cycleCount;

    final lastClaim = _parseDate(player.lastClaimDate!);
    final today = now();
    final daysSinceLastClaim = today.difference(lastClaim).inDays;

    // If we're on day 7 and continuing (consecutive or reset), increment cycle
    if (player.claimedDay == 7 && (daysSinceLastClaim == 1 || (daysSinceLastClaim > 1 && kResetStreakOnMiss))) {
      return player.cycleCount + 1;
    }

    return player.cycleCount;
  }

  /// Claim today's daily reward.
  ///
  /// Returns the DailyReward if successful, null if already claimed today.
  /// Applies coins/hints/targets to PlayerState and saves once.
  DailyReward? claim() {
    if (!canClaimToday) {
      return null;
    }

    final day = dayToClaim;
    final cycle = cycleToClaim;
    final reward = rewardFor(cycle, day);
    final todayStr = _todayString();

    // Update player state with all reward values in one batch operation
    player.claimDailyRewardNoSave(
      coins: reward.coins,
      hints: reward.hints,
      targets: reward.targets,
      date: todayStr,
      day: day,
      cycle: cycle,
    );
    player.save();

    return reward;
  }
}
