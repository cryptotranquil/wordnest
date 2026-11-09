import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wordnest/src/data/missions.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/panel_kit.dart';

/// Missions & Quests: daily missions and long-term achievements.
///
/// UI step only: the progress numbers below are preview values. Step 2
/// (functionality) replaces [_previewProgress] with real tracking and makes
/// "Claim" credit coins and persist.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  /// id -> current progress. Same numbers as the design mockup.
  static const Map<String, int> _previewProgress = <String, int>{
    'find_bonus_words': 5,
    'solve_puzzles': 3,
    'play_minutes': 7,
    'no_hint_level': 0,
    'lexicon_scholar': 112,
    'chapter_clearer': 1,
    'flawless_solver': 3,
  };

  int _tab = 0;
  final Set<String> _claimed = <String>{};
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _resetsIn() {
    final DateTime now = DateTime.now();
    final DateTime midnight = DateTime(now.year, now.month, now.day + 1);
    final Duration left = midnight.difference(now);
    final int h = left.inHours;
    final int m = left.inMinutes % 60;
    return 'Resets in ${h}h ${m}m';
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'book':
        return Icons.auto_stories_outlined;
      case 'check':
        return Icons.check_circle_outline_rounded;
      case 'clock':
        return Icons.schedule_rounded;
      case 'target':
        return Icons.track_changes_rounded;
      case 'workspace_premium_rounded':
        return Icons.workspace_premium_outlined;
      case 'explore_rounded':
        return Icons.explore_outlined;
      case 'verified_rounded':
        return Icons.verified_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PanelColors.bgBottom,
      body: PanelBackdrop(
        child: SafeArea(
          bottom: false,
          child: PhoneFrame(
            child: Column(
              children: <Widget>[
                ScreenHeader(
                  title: 'Missions & Quests',
                  trailing: _tab == 0
                      ? HeaderPill(label: _resetsIn(), icon: Icons.schedule_rounded, iconColor: AppColors.cream)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _TabSwitch(
                    index: _tab,
                    labels: const <String>['Daily', 'Achievements'],
                    onChanged: (int i) => setState(() => _tab = i),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: _tab == 0 ? _dailyCards() : _achievementCards(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _dailyCards() {
    return <Widget>[
      for (final DailyMission m in MissionBook.dailyMissions)
        _QuestCard(
          icon: _iconFor(m.icon),
          title: m.title,
          subtitle: m.description,
          reward: m.rewardCoins,
          progress: _previewProgress[m.id] ?? 0,
          target: m.target,
          unit: m.unit,
          claimed: _claimed.contains(m.id),
          onClaim: () => setState(() => _claimed.add(m.id)),
        ),
    ];
  }

  List<Widget> _achievementCards() {
    return <Widget>[
      for (final Achievement a in MissionBook.achievements) _achievementCard(a),
    ];
  }

  Widget _achievementCard(Achievement a) {
    final int value = _previewProgress[a.id] ?? 0;
    // First tier not yet reached; if all are reached, show the last one.
    int tier = a.tiers.indexWhere((int t) => value < t);
    if (tier == -1) tier = a.tiers.length - 1;
    final String key = '${a.id}#$tier';
    return _QuestCard(
      icon: _iconFor(a.icon),
      title: '${a.title} ${_roman(tier + 1)}',
      subtitle: a.description,
      reward: a.rewardCoins[tier],
      progress: value,
      target: a.tiers[tier],
      unit: '',
      claimed: _claimed.contains(key),
      onClaim: () => setState(() => _claimed.add(key)),
    );
  }

  String _roman(int n) => const <String>['', 'I', 'II', 'III', 'IV', 'V'][n.clamp(1, 5)];
}

class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.index, required this.labels, required this.onChanged});

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: PanelColors.pill,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    labels[i],
                    style: AppText.label(
                      15,
                      weight: 700,
                      color: i == index ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.progress,
    required this.target,
    required this.unit,
    required this.claimed,
    required this.onClaim,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int reward;
  final int progress;
  final int target;
  final String unit;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final bool done = progress >= target;
    final String counter = unit.isEmpty ? '$progress / $target' : '$progress / $target $unit';

    return PanelCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconTile(icon: icon, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppText.quicksand(18, weight: 700, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppText.label(13.5, weight: 500, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _trailing(done),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              counter,
              style: AppText.label(13.5, weight: 600, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 8),
          SlimProgress(value: target == 0 ? 0 : progress / target, height: 7),
        ],
      ),
    );
  }

  Widget _trailing(bool done) {
    if (claimed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.teal),
          const SizedBox(width: 5),
          Text('Claimed', style: AppText.label(13.5, weight: 700, color: AppColors.teal)),
        ],
      );
    }
    if (done) {
      return GestureDetector(
        onTap: onClaim,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Text(
            'Claim +$reward',
            style: AppText.quicksand(16, weight: 700, color: AppColors.goldInk),
          ),
        ),
      );
    }
    return Text(
      '+$reward',
      style: AppText.quicksand(20, weight: 700, color: AppColors.gold),
    );
  }
}
