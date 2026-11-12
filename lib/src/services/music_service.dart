import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../state/settings_state.dart';

/// The small playback interface also lets tests exercise startup without a
/// platform audio plugin or a browser.
abstract class MusicPlayback {
  Future<void> setLoop();
  Future<void> setVolume(double volume);
  Future<void> playAsset(String path);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class _AudioPlayerPlayback implements MusicPlayback {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> setLoop() => _player.setReleaseMode(ReleaseMode.loop);
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> playAsset(String path) => _player.play(AssetSource(path));
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() => _player.dispose();
}

/// Serializes music changes so rapid chapter/settings changes cannot leave two
/// tracks playing. Browsers must receive a user gesture before any play call.
class MusicService {
  MusicService._() : _playback = _AudioPlayerPlayback(), _hasGesture = !kIsWeb;

  @visibleForTesting
  MusicService.forTesting({required MusicPlayback playback, required bool requiresGesture})
      : _playback = playback, _hasGesture = !requiresGesture;

  static final MusicService instance = MusicService._();
  final MusicPlayback _playback;
  Future<void> _queue = Future.value();
  bool _initialized = false;
  bool _foreground = true;
  bool _playing = false;
  bool _hasGesture;
  int? _wantedChapter;
  int? _loadedChapter;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _playback.setLoop();
      _initialized = true;
      SettingsState.instance.addListener(_onSettingsChanged);
      await _schedule();
    } catch (error) {
      debugPrint('Music initialization failed: $error');
    }
  }

  void _onSettingsChanged() { _schedule(); }

  /// Record gestures even during startup; the requested chapter may arrive
  /// later. Without this gate Chrome can leave its resume future pending,
  /// blocking both the splash screen and every subsequently queued retry.
  Future<void> onUserInteraction() {
    _hasGesture = true;
    if (_initialized && !_playing && _foreground && SettingsState.instance.musicOn) {
      return _schedule();
    }
    return Future.value();
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
          if (_playing) await _playback.pause();
          _playing = false;
          return;
        }
        // Do not create a source or call play/resume on web before a gesture.
        if (!_hasGesture) return;
        await _playback.setVolume(settings.musicVolume * .8);
        if (_loadedChapter != chapter) {
          await _playback.stop();
          await _playback.playAsset('audio/music/${['chapter_forest', 'chapter_ocean', 'chapter_cosmos'][chapter]}.mp3');
          _loadedChapter = chapter;
          _playing = true;
        } else if (!_playing) {
          await _playback.resume();
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
    unawaited(_playback.dispose());
  }
}
