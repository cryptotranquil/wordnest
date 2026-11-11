import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../state/settings_state.dart';

/// Serializes music changes so rapid chapter/settings changes cannot leave two
/// tracks playing. Asset paths are relative to Flutter's assets/ directory.
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();
  final AudioPlayer _player = AudioPlayer();
  Future<void> _queue = Future.value();
  bool _initialized = false;
  bool _foreground = true;
  bool _playing = false;
  int? _wantedChapter;
  int? _loadedChapter;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      _initialized = true;
      SettingsState.instance.addListener(_onSettingsChanged);
      await _schedule();
    } catch (error) {
      debugPrint('Music initialization failed: $error');
    }
  }

  void _onSettingsChanged() { _schedule(); }

  /// Web browsers may reject autoplay until a gesture. Retry on interaction.
  void onUserInteraction() {
    if (_initialized && !_playing && _foreground && SettingsState.instance.musicOn) {
      _schedule();
    }
  }

  Future<void> playForChapter(int chapterIndex) {
    _wantedChapter = chapterIndex.clamp(0, 2);
    return _schedule();
  }

  Future<void> _schedule() {
    _queue = _queue.catchError((Object error) {
      debugPrint('Music playback failed: $error');
    }).then((_) async {
      if (!_initialized) return;
      try {
        final settings = SettingsState.instance;
        final chapter = _wantedChapter;
        if (!_foreground || !settings.musicOn || chapter == null) {
          if (_playing) await _player.pause();
          _playing = false;
          return;
        }
        await _player.setVolume(settings.musicVolume * .8);
        if (_loadedChapter != chapter) {
          await _player.stop();
          await _player.play(AssetSource('audio/music/${['chapter_forest', 'chapter_ocean', 'chapter_cosmos'][chapter]}.mp3'));
          _loadedChapter = chapter;
          _playing = true;
        } else if (!_playing) {
          await _player.resume();
          _playing = true;
        }
      } catch (error) {
        _playing = false;
        _loadedChapter = null;
        debugPrint('Music playback failed: $error');
      }
    });
    return _queue;
  }

  Future<void> pause() { _foreground = false; return _schedule(); }
  Future<void> resume() { _foreground = true; return _schedule(); }
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resume();
    } else {
      pause();
    }
  }

  void dispose() {
    SettingsState.instance.removeListener(_onSettingsChanged);
    _initialized = false;
    unawaited(_player.dispose());
  }
}
