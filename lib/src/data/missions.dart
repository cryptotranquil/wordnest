class DailyMission {
  final String id;
  final String title;
  final String description;
  final int target;
  final int rewardCoins;
  final int rewardHints;
  final String icon;

  /// Shown after the progress numbers, e.g. "7 / 10 min".
  final String unit;

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.rewardCoins,
    required this.rewardHints,
    required this.icon,
    this.unit = '',
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final List<int> tiers;
  final List<int> rewardCoins;
  final List<int> rewardHints;
  final String icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.tiers,
    required this.rewardCoins,
    required this.rewardHints,
    required this.icon,
  });
}

class MissionBook {
  static const List<DailyMission> dailyMissions = [
    DailyMission(
      id: 'find_bonus_words',
      title: 'Find 10 bonus words',
      description: 'Discover words outside the grid',
      target: 10,
      rewardCoins: 50,
      rewardHints: 0,
      icon: 'book',
    ),
    DailyMission(
      id: 'solve_puzzles',
      title: 'Solve 3 puzzles',
      description: 'Complete any three levels',
      target: 3,
      rewardCoins: 30,
      rewardHints: 0,
      icon: 'check',
    ),
    DailyMission(
      id: 'play_minutes',
      title: 'Play for 10 minutes',
      description: 'Keep going across any levels',
      target: 10,
      rewardCoins: 20,
      rewardHints: 0,
      icon: 'clock',
      unit: 'min',
    ),
    DailyMission(
      id: 'no_hint_level',
      title: 'Finish a level, no hints',
      description: 'Solve one without any help',
      target: 1,
      rewardCoins: 40,
      rewardHints: 0,
      icon: 'target',
    ),
  ];

  static const List<Achievement> achievements = [
    Achievement(
      id: 'lexicon_scholar',
      title: 'Lexicon Scholar',
      description: 'Find bonus words in sanctuary',
      tiers: [50, 100, 150],
      rewardCoins: [100, 200, 300],
      rewardHints: [0, 0, 0],
      icon: 'workspace_premium_rounded',
    ),
    Achievement(
      id: 'chapter_clearer',
      title: 'Chapter Clearer',
      description: 'Clear chapters of the sanctuary',
      tiers: [1, 2, 3],
      rewardCoins: [100, 200, 300],
      rewardHints: [0, 0, 0],
      icon: 'explore_rounded',
    ),
    Achievement(
      id: 'flawless_solver',
      title: 'Flawless Solver',
      description: 'Solve levels with 100% precision',
      tiers: [1, 5, 10],
      rewardCoins: [100, 200, 300],
      rewardHints: [0, 0, 0],
      icon: 'verified_rounded',
    ),
    // Add more achievements as needed
  ];
}