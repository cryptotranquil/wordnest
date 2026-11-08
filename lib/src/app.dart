import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'state/player_state.dart';
import 'state/settings_state.dart';
import 'theme/wordnest_theme.dart';

class WordnestApp extends StatefulWidget {
  const WordnestApp({super.key});

  @override
  State<WordnestApp> createState() => _WordnestAppState();
}

class _WordnestAppState extends State<WordnestApp> {
  final PlayerState _player = PlayerState();

  @override
  void initState() {
    super.initState();
    // Initialize SettingsState from shared preferences
    SettingsState.instance.load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordNest',
      debugShowCheckedModeBanner: false,
      theme: buildWordnestTheme(),
      navigatorKey: SettingsState.instance.navigatorKey,
      home: SplashScreen(player: _player),
    );
  }
}