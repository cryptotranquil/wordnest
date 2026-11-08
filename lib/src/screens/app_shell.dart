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
    final screens = <Widget>[
      HomeScreen(player: widget.player),
      ChaptersScreen(player: widget.player),
      const MissionsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.glassLine.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.cottage_rounded, 'Home'),
          _buildNavItem(1, Icons.menu_book_rounded, 'Chapters'),
          _buildNavItem(2, Icons.military_tech_rounded, 'Missions'),
          _buildNavItem(3, Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Icon(
            icon,
            size: 24,
            color: isActive ? AppColors.gold : AppColors.muted,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.label(
              10,
              weight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.gold : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}