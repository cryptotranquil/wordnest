import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/chapter.dart';
import 'screens/splash_screen.dart';
import 'services/music_service.dart';
import 'services/sound_service.dart';
import 'state/player_state.dart';
import 'state/settings_state.dart';
import 'state/stats_state.dart';
import 'theme/wordnest_theme.dart';

class WordnestApp extends StatefulWidget {
  const WordnestApp({super.key});
  @override
  State<WordnestApp> createState() => _WordnestAppState();
}

class _WordnestAppState extends State<WordnestApp> with WidgetsBindingObserver {
  final PlayerState _player = PlayerState();
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_player.load(), SettingsState.instance.load(), StatsState.instance.load()]);
    try {
      await SoundService.instance.init();
    } catch (error) {
      debugPrint('Sound initialization failed: $error');
    }
    try {
      await MusicService.instance.init();
      final chapter = ChapterBook.chapterForLevel(_player.currentLevel);
      await MusicService.instance.playForChapter((chapter?.id ?? 1) - 1);
    } catch (error) {
      debugPrint('Audio initialization failed: $error');
    }
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) MusicService.instance.onUserInteraction();
    return false; // Do not consume keyboard navigation or shortcuts.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    MusicService.instance.handleAppLifecycleStateChanged(state);
    if (state == AppLifecycleState.resumed) StatsState.instance.refreshDay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WordNest', debugShowCheckedModeBanner: false,
    theme: buildWordnestTheme(), navigatorKey: SettingsState.instance.navigatorKey,
    builder: (context, child) => Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => MusicService.instance.onUserInteraction(),
      child: child ?? const SizedBox.shrink(),
    ),
    home: SplashScreen(player: _player, ready: _ready),
  );
}
