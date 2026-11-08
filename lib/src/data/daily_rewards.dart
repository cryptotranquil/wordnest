/// Reward tiers for daily claims.
///
/// Cycle 0 = week 1, cycle 1 = week 2, cycle 2+ = week 3+ (clamped).
/// Day is 1-7 (Monday-Sunday).
class DailyReward {
  const DailyReward({required this.coins, required this.hints, required this.targets});

  final int coins;
  final int hints;
  final int targets;

  DailyReward copyWith({int? coins, int? hints, int? targets}) {
    return DailyReward(
      coins: coins ?? this.coins,
      hints: hints ?? this.hints,
      targets: targets ?? this.targets,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailyReward &&
        other.coins == coins &&
        other.hints == hints &&
        other.targets == targets;
  }

  @override
  int get hashCode => Object.hash(coins, hints, targets);

  @override
  String toString() => 'DailyReward(coins: $coins, hints: $hints, targets: $targets)';
}

/// Reward table: cycle 0=week1, 1=week2, 2+=week3+
/// Day is 1-7.
///
/// Week 1:
///   D1 50c | D2 1 hint | D3 100c | D4 150c+1 hint | D5 200c | D6 1 target | D7 500c+1 hint+1 target
/// Week 2:
///   D1 75c | D2 2 hints | D3 150c | D4 225c+1 hint | D5 300c | D6 1 target+50c | D7 750c+2 hints+1 target
/// Week 3+:
///   D1 100c | D2 2 hints+50c | D3 200c | D4 300c+2 hints | D5 400c | D6 2 targets | D7 1000c+2 hints+2 targets
///
/// Keep all numbers in one place for easy tuning.
final List<List<DailyReward>> kDailyRewards = <List<DailyReward>>[
  // Week 1 (cycle 0)
  <DailyReward>[
    DailyReward(coins: 50, hints: 0, targets: 0),      // D1
    DailyReward(coins: 0, hints: 1, targets: 0),       // D2
    DailyReward(coins: 100, hints: 0, targets: 0),     // D3
    DailyReward(coins: 150, hints: 1, targets: 0),     // D4
    DailyReward(coins: 200, hints: 0, targets: 0),     // D5
    DailyReward(coins: 0, hints: 0, targets: 1),       // D6
    DailyReward(coins: 500, hints: 1, targets: 1),     // D7
  ],
  // Week 2 (cycle 1)
  <DailyReward>[
    DailyReward(coins: 75, hints: 0, targets: 0),      // D1
    DailyReward(coins: 0, hints: 2, targets: 0),       // D2
    DailyReward(coins: 150, hints: 0, targets: 0),     // D3
    DailyReward(coins: 225, hints: 1, targets: 0),     // D4
    DailyReward(coins: 300, hints: 0, targets: 0),     // D5
    DailyReward(coins: 50, hints: 0, targets: 1),      // D6
    DailyReward(coins: 750, hints: 2, targets: 1),     // D7
  ],
  // Week 3+ (cycle 2+)
  <DailyReward>[
    DailyReward(coins: 100, hints: 0, targets: 0),     // D1
    DailyReward(coins: 50, hints: 2, targets: 0),      // D2
    DailyReward(coins: 200, hints: 0, targets: 0),     // D3
    DailyReward(coins: 300, hints: 2, targets: 0),     // D4
    DailyReward(coins: 400, hints: 0, targets: 0),     // D5
    DailyReward(coins: 0, hints: 0, targets: 2),       // D6
    DailyReward(coins: 1000, hints: 2, targets: 2),    // D7
  ],
];

/// Clamp cycle to [0, 1, 2+] where 2+ means week 3 and beyond.
int clampCycle(int cycle) => cycle < 0 ? 0 : cycle > 1 ? 2 : cycle;

/// Get the reward for a given cycle and day (1-7).
DailyReward rewardFor(int cycle, int day) {
  final clampedCycle = clampCycle(cycle);
  final dayIndex = day - 1; // Convert 1-7 to 0-6
  return kDailyRewards[clampedCycle][dayIndex];
}
