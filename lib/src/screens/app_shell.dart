import 'package:flutter/material.dart';
import 'package:wordnest/src/screens/chapters_screen.dart';
import 'package:wordnest/src/screens/home_screen.dart';
import 'package:wordnest/src/screens/missions_screen.dart';
import 'package:wordnest/src/screens/settings_screen.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/state/settings_state.dart';
import 'package:wordnest/src/services/sound_service.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.player});
  final PlayerState player;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Tabs are not Navigator routes, so keep their own back history.
  final List<int> _tabHistory = [0];
  int get _currentIndex => _tabHistory.last;

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      if (index == 0) {
        _tabHistory
          ..clear()
          ..add(0);
      } else {
        // Keep the most recent visit to each tab without unbounded growth.
        _tabHistory.remove(index);
        _tabHistory.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _tabHistory.length == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _tabHistory.length > 1) {
          setState(() => _tabHistory.removeLast());
        }
      },
      child: Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        HomeScreen(player: widget.player, onMissions: () => _selectTab(2)),
        ChaptersScreen(player: widget.player),
        MissionsScreen(player: widget.player),
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
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    return Expanded(child: Semantics(
      key: ValueKey('navigation-tab-$index'),
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          if (SettingsState.instance.soundOn) {
            SoundService.instance.play(SoundId.uiTap);
          }
          _selectTab(index);
        },
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 24, color: active ? AppColors.teal : AppColors.muted),
          const SizedBox(height: 4),
          Text(label, style: AppText.label(10, weight: active ? 700 : 500, color: active ? AppColors.teal : AppColors.muted)),
        ]),
      ),
    ));
  }
}
