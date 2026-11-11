class DailyMission {
  const DailyMission(this.id, this.title, this.description, this.target, this.rewardCoins);
  final String id;
  final String title;
  final String description;
  /// Play time is measured in seconds; other goals are counts.
  final int target;
  final int rewardCoins;
}

class Achievement {
  const Achievement(this.id, this.title, this.description, this.tiers, this.rewardCoins);
  final String id;
  final String title;
  final String description;
  final List<int> tiers;
  final List<int> rewardCoins;
}

abstract final class MissionBook {
  static const dailyMissions = <DailyMission>[
    DailyMission('bonus', 'Find 10 bonus words', 'Discover words outside the grid', 10, 50),
    DailyMission('levels', 'Solve 3 puzzles', 'Complete any three levels', 3, 30),
    DailyMission('time', 'Play for 10 minutes', 'Keep going across any levels', 600, 20),
    DailyMission('no_hints', 'Finish a level, no hints', 'Solve one without any help', 1, 40),
  ];
  static const achievements = <Achievement>[
    Achievement('lexicon', 'Lexicon Scholar', 'Find bonus words', [50, 100, 150], [100, 200, 300]),
    Achievement('chapters', 'Chapter Clearer', 'Clear chapters of the sanctuary', [1, 2, 3], [100, 200, 300]),
    Achievement('flawless', 'Flawless Solver', 'Complete levels without incorrect words', [1, 5, 10], [100, 200, 300]),
  ];
}
