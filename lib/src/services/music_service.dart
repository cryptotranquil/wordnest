import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/scheduler.dart';

import 'package:wordnest/src/state/settings_state.dart';

/// Background music service for WordNest.
/// Handles chapter-specific tracks with crossfading and volume control.
class MusicService {
  MusicService._();

  static final MusicService instance = MusicService._();

  final AudioPlayer _player1 = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer();
  late AudioPlayer _activePlayer;
  late AudioPlayer _inactivePlayer;

  int _currentChapterIndex = -1;
  bool _musicOn = true;
  bool _disposed = false;
  StreamSubscription<SettingsState>? _settingsSubscription;
  double _currentVolume = 0.0;

  Future<void> init() async {
    _activePlayer = _player1;
    _inactivePlayer = _player2;
    await _activePlayer.setReleaseMode(ReleaseMode.loop);
    await _inactivePlayer.setReleaseMode(ReleaseMode.loop);
    await _updateVolume();
    _listenToSettings();
  }

  void _listenToSettings() {
    // When musicOn setting changes
    SettingsState.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    _musicOn = SettingsState.instance.musicOn;
    final volume = SettingsState.instance.musicVolume;
    if (_musicOn) {
      _fadeToVolume(volume * 0.8);
    } else {
      _fadeOut();
    }
  }

  Future<void> _updateVolume() async {
    final volume = SettingsState.instance.musicVolume;
    _currentVolume = volume * 0.8;
    await _activePlayer.setVolume(volume * 0.8);
    await _inactivePlayer.setVolume(volume * 0.8);
  }

  Future<void> _fadeToVolume(double targetVolume) async {
    final current = _currentVolume;
    final difference = targetVolume - current;
    if (difference.abs() < 0.01) return;

    _currentVolume = targetVolume;

    final duration = const Duration(milliseconds: 400);
    final frames = 20;
    final frameDuration = duration.inMilliseconds / frames;
    final step = difference / frames;

    for (int i = 0; i < frames; i++) {
      await _activePlayer.setVolume(current + step * (i + 1));
      await Future.delayed(Duration(milliseconds: frameDuration.toInt()));
    }
  }

  Future<void> _fadeOut() async {
    final duration = const Duration(milliseconds: 400);
    final frames = 20;
    final frameDuration = duration.inMilliseconds / frames;
    final current = _currentVolume;

    for (int i = 0; i < frames; i++) {
      await _activePlayer.setVolume(current * (1 - (i + 1) / frames));
      await Future.delayed(Duration(milliseconds: frameDuration.toInt()));
    }
    _currentVolume = 0.0;
  }

  void setMusicOn(bool value) {
    _musicOn = value;
  }

  Future<void> playForChapter(int chapterIndex) async {
    if (_disposed) return;

    final normalizedChapter = chapterIndex % 3;
    if (normalizedChapter == _currentChapterIndex && _musicOn) {
      return; // Same chapter and music is on, keep playing
    }

    if (normalizedChapter == _currentChapterIndex && !_musicOn) {
      await _fadeIn();
      return;
    }

    if (!_musicOn) return;

    final newTrack = _trackForChapter(normalizedChapter);
    await _crossfadeTo(newTrack);
    _currentChapterIndex = normalizedChapter;
  }

  String _trackForChapter(int chapterIndex) {
    switch (chapterIndex) {
      case 0:
        return 'assets/audio/music/chapter_forest.mp3';
      case 1:
        return 'assets/audio/music/chapter_ocean.mp3';
      case 2:
        return 'assets/audio/music/chapter_cosmos.mp3';
      default:
        return 'assets/audio/music/chapter_forest.mp3';
    }
  }

  Future<void> _crossfadeTo(String newTrack) async {
    if (_disposed) return;

    // Play on inactive player
    try {
      await _inactivePlayer.setSource(AssetSource(newTrack.replaceFirst('assets/audio/', '')));
      await _inactivePlayer.setVolume((SettingsState.instance.musicVolume) * 0.8);
      await _inactivePlayer.resume();
    } catch (e) {
      return; // Silently ignore errors
    }

    // Fade out active player
    final duration = const Duration(milliseconds: 2000);

    await _activePlayer.pause();
    await Future.delayed(duration);

    // Switch active/inactive
    final temp = _activePlayer;
    _activePlayer = _inactivePlayer;
    _inactivePlayer = temp;
  }

  Future<void> _fadeIn() async {
    final targetVolume = SettingsState.instance.musicVolume * 0.8;
    await _activePlayer.resume();
    await _fadeToVolume(targetVolume);
  }

  Future<void> pause() async {
    if (_disposed) return;
    await _activePlayer.pause();
    _musicOn = false;
  }

  Future<void> resume() async {
    if (_disposed) return;
    if (!SettingsState.instance.musicOn) return;

    await _activePlayer.resume();
    await _fadeToVolume(SettingsState.instance.musicVolume * 0.8);
    _musicOn = true;
  }

  /// Call this when a reward sound plays to lower music volume temporarily
  void lowerForReward() async {
    await _activePlayer.setVolume((SettingsState.instance.musicVolume) * 0.8 * 0.5);
  }

  /// Restore music volume after reward sound
  void restoreAfterReward() async {
    await _activePlayer.setVolume((SettingsState.instance.musicVolume) * 0.8);
  }

  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.paused) {
      _activePlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_musicOn && SettingsState.instance.musicOn) {
        _activePlayer.resume();
      }
    }
  }

  void dispose() {
    _disposed = true;
    _settingsSubscription?.cancel();
    SettingsState.instance.removeListener(_onSettingsChanged);
    _activePlayer.dispose();
    _inactivePlayer.dispose();
  }
}