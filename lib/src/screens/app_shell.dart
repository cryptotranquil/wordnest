import 'package:flutter/material.dart';
import 'package:wordnest/src/screens/chapters_screen.dart';
import 'package:wordnest/src/screens/home_screen.dart';
import 'package:wordnest/src/screens/missions_screen.dart';
import 'package:wordnest/src/screens/settings_screen.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.player});
  final PlayerState player;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        HomeScreen(player: widget.player),
        ChaptersScreen(player: widget.player),
        const MissionsScreen(),
        const SettingsScreen(),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.inkDeep,
          border: Border(top: BorderSide(color: AppColors.muted.withValues(alpha: .14))),
        ),
        child: SafeArea(top: false, child: SizedBox(height: 68, child: Row(children: [
          _navItem(0, Icons.home_outlined, 'Home'),
          _navItem(1, Icons.menu_book_outlined, 'Chapters'),
          _navItem(2, Icons.emoji_events_outlined, 'Missions'),
          _navItem(3, Icons.settings_outlined, 'Settings'),
        ]))),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    return Expanded(child: Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 24, color: active ? AppColors.teal : AppColors.muted),
          const SizedBox(height: 4),
          Text(label, style: AppText.label(10, weight: active ? 700 : 500, color: active ? AppColors.teal : AppColors.muted)),
        ]),
      ),
    ));
  }
}
