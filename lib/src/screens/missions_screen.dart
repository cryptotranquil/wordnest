import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wordnest/src/data/missions.dart';
import 'package:wordnest/src/services/sound_service.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/state/stats_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key, required this.player, this.stats});
  final PlayerState player;
  final StatsState? stats;
  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  int _selectedTab = 0;
  Timer? _timer;
  StatsState get stats => widget.stats ?? StatsState.instance;

  @override
  void initState() {
    super.initState();
    stats.refreshDay();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      stats.refreshDay();
      if (mounted) setState(() {});
    });
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(child: AnimatedBuilder(
      animation: Listenable.merge([stats, widget.player]),
      builder: (context, _) {
        final remaining = stats.timeUntilReset;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(children: [
              Expanded(child: Text('Missions & Quests', style: AppText.quicksand(24, weight: 700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: .6), borderRadius: BorderRadius.circular(30)),
                child: Text('Resets in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m', style: AppText.label(10, color: AppColors.muted)),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF1B3838), borderRadius: BorderRadius.circular(40)),
            child: Row(children: [_tab('Daily', 0), _tab('Achievements', 1)]),
          )),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: _selectedTab == 0 ? [
              for (final mission in MissionBook.dailyMissions) _dailyCard(mission),
            ] : [
              for (final achievement in MissionBook.achievements) _achievementCard(achievement),
            ],
          )),
        ]);
      },
    )),
  );

  Widget _dailyCard(DailyMission mission) {
    final progress = stats.dailyProgress(mission.id);
    final claimed = widget.player.dailyClaimed(stats.today, mission.id);
    final done = progress >= mission.target && stats.isCurrentDay;
    final icon = switch (mission.id) {
      'bonus' => Icons.menu_book_outlined,
      'levels' => Icons.check_circle_outline,
      'time' => Icons.access_time_rounded,
      _ => Icons.track_changes_rounded,
    };
    final progressText = mission.id == 'time'
        ? '${(progress ~/ 60).clamp(0, 10)} / 10 min'
        : '${progress.clamp(0, mission.target)} / ${mission.target}';
    return _MissionCard(icon: icon, title: mission.title, description: mission.description,
      reward: mission.rewardCoins, progress: (progress / mission.target).clamp(0.0, 1.0),
      progressText: progressText, claimed: claimed,
      onClaim: done && !claimed ? () {
        stats.refreshDay();
        if (!stats.isCurrentDay || stats.dailyProgress(mission.id) < mission.target) return;
        if (widget.player.claimDailyMission(stats.today, mission.id, mission.rewardCoins)) {
          SoundService.instance.play(SoundId.missionClaim);
        }
      } : null,
    );
  }

  Widget _achievementCard(Achievement achievement) {
    final claimed = widget.player.achievementTierClaimed(achievement.id);
    final complete = claimed >= achievement.tiers.length;
    final index = complete ? achievement.tiers.length - 1 : claimed;
    final target = achievement.tiers[index];
    final progress = switch (achievement.id) {
      'lexicon' => stats.bonusWordsFound,
      'chapters' => widget.player.finishedJourney ? 3 : ((widget.player.currentLevel - 1) ~/ 20).clamp(0, 3),
      _ => stats.flawlessLevels,
    };
    return _MissionCard(icon: Icons.workspace_premium_outlined, title: '${achievement.title} ${index + 1}',
      description: achievement.description, reward: achievement.rewardCoins[index],
      progress: (progress / target).clamp(0.0, 1.0), progressText: '${progress.clamp(0, target)} / $target',
      claimed: complete,
      onClaim: !complete && progress >= target ? () {
        if (widget.player.claimAchievement(achievement.id, index + 1, achievement.rewardCoins[index])) {
          SoundService.instance.play(SoundId.missionClaim);
        }
      } : null,
    );
  }

  Widget _tab(String title, int index) {
    final selected = _selectedTab == index;
    return Expanded(child: Semantics(selected: selected, button: true, child: InkWell(
      borderRadius: BorderRadius.circular(40), onTap: () => setState(() => _selectedTab = index),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: selected ? AppColors.teal : Colors.transparent, borderRadius: BorderRadius.circular(40)),
        alignment: Alignment.center, child: Text(title, style: AppText.label(14, weight: 700, color: selected ? AppColors.ink : AppColors.muted))),
    )));
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.icon, required this.title, required this.description, required this.reward,
    required this.progress, required this.progressText, required this.claimed, this.onClaim});
  final IconData icon;
  final String title, description, progressText;
  final int reward;
  final double progress;
  final bool claimed;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF123130), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF204947), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.teal, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.quicksand(16, weight: 700)),
          const SizedBox(height: 3), Text(description, style: AppText.label(11, weight: 500, color: AppColors.muted)),
        ])),
        const SizedBox(width: 6),
        if (onClaim != null) FilledButton(
          onPressed: onClaim,
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ink, padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Text('Claim +$reward', style: AppText.label(11, color: AppColors.ink)),
        ) else Text(claimed ? 'Claimed' : '+$reward', style: AppText.label(13, weight: 700, color: claimed ? AppColors.muted : AppColors.gold)),
      ]),
      const SizedBox(height: 18),
      Align(alignment: Alignment.centerRight, child: Text(progressText, style: AppText.label(12, color: AppColors.muted))),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: const Color(0xFF325451), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal))),
    ]),
  );
}
