import 'package:flutter/material.dart';
import 'package:wordnest/src/data/missions.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';

/// Mission tracking and claiming are not wired up yet. The cards deliberately
/// show no invented progress or claim buttons until that work is implemented.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(children: [
              Expanded(child: Text('Missions & Quests', style: AppText.quicksand(24, weight: 700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: AppColors.glassLine.withValues(alpha: .6), borderRadius: BorderRadius.circular(30)),
                child: Text('Coming soon', style: AppText.label(10, color: AppColors.muted)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF1B3838), borderRadius: BorderRadius.circular(40)),
              child: Row(children: [
                _tab('Daily', 0),
                _tab('Achievements', 1),
              ]),
            ),
          ),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Progress and rewards are coming in a future update.', style: AppText.label(12, color: AppColors.muted)),
              ),
              if (_selectedTab == 0) ...[
                const _MissionCard(icon: Icons.menu_book_outlined, title: 'Find 10 bonus words', description: 'Discover words outside the grid', reward: 50),
                const _MissionCard(icon: Icons.check_circle_outline, title: 'Solve 3 puzzles', description: 'Complete any three levels', reward: 30),
                const _MissionCard(icon: Icons.access_time_rounded, title: 'Play for 10 minutes', description: 'Keep going across any levels', reward: 20),
                const _MissionCard(icon: Icons.track_changes_rounded, title: 'Finish a level, no hints', description: 'Solve one without any help', reward: 40),
              ] else ...[
                for (final achievement in MissionBook.achievements)
                  _MissionCard(
                    icon: Icons.workspace_premium_outlined,
                    title: achievement.title,
                    description: achievement.description,
                    reward: achievement.rewardCoins.first,
                  ),
              ],
            ],
          )),
        ]),
      ),
    );
  }

  Widget _tab(String title, int index) {
    final selected = _selectedTab == index;
    return Expanded(child: Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: selected ? AppColors.teal : Colors.transparent, borderRadius: BorderRadius.circular(40)),
          alignment: Alignment.center,
          child: Text(title, style: AppText.label(14, weight: 700, color: selected ? AppColors.ink : AppColors.muted)),
        ),
      ),
    ));
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.icon, required this.title, required this.description, required this.reward});
  final IconData icon;
  final String title;
  final String description;
  final int reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF123130), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFF204947), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.teal, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.quicksand(16, weight: 700)),
            const SizedBox(height: 3),
            Text(description, style: AppText.label(11, weight: 500, color: AppColors.muted)),
          ])),
          const SizedBox(width: 6),
          Text('+$reward', style: AppText.label(15, weight: 700, color: AppColors.gold)),
        ]),
        const SizedBox(height: 18),
        Align(alignment: Alignment.centerRight, child: Text('—', style: AppText.label(12, color: AppColors.muted))),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(
          value: 0, minHeight: 6, backgroundColor: Color(0xFF325451), valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
        )),
      ]),
    );
  }
}
