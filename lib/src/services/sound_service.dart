import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import '../state/settings_state.dart';
import 'package:flutter/foundation.dart';

/// Sound effects service for WordNest.
/// Uses a pool of AudioPlayers for low-latency playback.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _uiTapPlayer = AudioPlayer();
  final AudioPlayer _togglePlayer = AudioPlayer();
  final AudioPlayer _letterPlayer = AudioPlayer();
  final AudioPlayer _wordCorrectPlayer = AudioPlayer();
  final AudioPlayer _wordBonusPlayer = AudioPlayer();
  final AudioPlayer _wordWrongPlayer = AudioPlayer();
  final AudioPlayer _wordRepeatPlayer = AudioPlayer();
  final AudioPlayer _shufflePlayer = AudioPlayer();
  final AudioPlayer _hintPlayer = AudioPlayer();
  final AudioPlayer _targetPlayer = AudioPlayer();
  final AudioPlayer _coinPlayer = AudioPlayer();
  final AudioPlayer _levelCompletePlayer = AudioPlayer();
  final AudioPlayer _rewardClaimPlayer = AudioPlayer();
  final AudioPlayer _chapterUnlockPlayer = AudioPlayer();
  final AudioPlayer _missionClaimPlayer = AudioPlayer();

  bool _soundOn = true;
  bool _disposed = false;
  bool _listening = false;
  bool _settingsSoundOn = true;

  void _onSettingsChanged() {
    final enabled = SettingsState.instance.soundOn;
    final justMuted = _settingsSoundOn && !enabled;
    _settingsSoundOn = enabled;
    if (!justMuted || _disposed) return;
    for (final player in <AudioPlayer>[
      _uiTapPlayer, _togglePlayer, _letterPlayer, _wordCorrectPlayer,
      _wordBonusPlayer, _wordWrongPlayer, _wordRepeatPlayer, _shufflePlayer,
      _hintPlayer, _targetPlayer, _coinPlayer, _levelCompletePlayer,
      _rewardClaimPlayer, _chapterUnlockPlayer, _missionClaimPlayer,
    ]) {
      unawaited(player.stop().catchError((Object error) {
        if (kDebugMode) debugPrint('Could not stop sound: $error');
      }));
    }
  }

  /// Initialize the service. Call this before playing sounds.
  Future<void> init() async {
    if (!_listening) {
      _settingsSoundOn = SettingsState.instance.soundOn;
      SettingsState.instance.addListener(_onSettingsChanged);
      _listening = true;
    }
    // Set release mode to stop after each sound
    await _uiTapPlayer.setReleaseMode(ReleaseMode.stop);
    await _togglePlayer.setReleaseMode(ReleaseMode.stop);
    await _letterPlayer.setReleaseMode(ReleaseMode.stop);
    await _wordCorrectPlayer.setReleaseMode(ReleaseMode.stop);
    await _wordBonusPlayer.setReleaseMode(ReleaseMode.stop);
    await _wordWrongPlayer.setReleaseMode(ReleaseMode.stop);
    await _wordRepeatPlayer.setReleaseMode(ReleaseMode.stop);
    await _shufflePlayer.setReleaseMode(ReleaseMode.stop);
    await _hintPlayer.setReleaseMode(ReleaseMode.stop);
    await _targetPlayer.setReleaseMode(ReleaseMode.stop);
    await _coinPlayer.setReleaseMode(ReleaseMode.stop);
    await _levelCompletePlayer.setReleaseMode(ReleaseMode.stop);
    await _rewardClaimPlayer.setReleaseMode(ReleaseMode.stop);
    await _chapterUnlockPlayer.setReleaseMode(ReleaseMode.stop);
    await _missionClaimPlayer.setReleaseMode(ReleaseMode.stop);
  }

  void setSoundOn(bool value) {
    _soundOn = value;
  }

  bool get soundOn => _soundOn;

  /// Play a sound effect.
  void play(SoundId id) {
    if (!_soundOn || !SettingsState.instance.soundOn || _disposed) return;
    _playOnPlayer(_getPlayerForSound(id), _soundNameFor(id));
  }

  String _soundNameFor(SoundId id) {
    switch (id) {
      case SoundId.uiTap: return 'ui_tap';
      case SoundId.toggle: return 'toggle';
      case SoundId.letter: return 'letter_1';
      case SoundId.wordCorrect: return 'word_correct';
      case SoundId.wordBonus: return 'word_bonus';
      case SoundId.wordWrong: return 'word_wrong';
      case SoundId.wordRepeat: return 'word_repeat';
      case SoundId.shuffle: return 'shuffle';
      case SoundId.hint: return 'hint';
      case SoundId.target: return 'target';
      case SoundId.coin: return 'coin';
      case SoundId.levelComplete: return 'level_complete';
      case SoundId.rewardClaim: return 'reward_claim';
      case SoundId.chapterUnlock: return 'chapter_unlock';
      case SoundId.missionClaim: return 'mission_claim';
    }
  }

  /// Play a letter sound based on position in swipe (1-7).
  void playLetter(int positionInSwipe) {
    if (!_soundOn || !SettingsState.instance.soundOn || _disposed) return;
    final clampedPos = positionInSwipe.clamp(1, 7);
    _playOnPlayer(_letterPlayer, 'letter_$clampedPos');
  }

  void _playOnPlayer(AudioPlayer player, String soundName) {
    unawaited(player.play(AssetSource('audio/sfx/$soundName.mp3')).catchError((Object error) {
      if (kDebugMode) debugPrint('Sound playback failed: $error');
    }));
  }

  AudioPlayer _getPlayerForSound(SoundId id) {
    switch (id) {
      case SoundId.uiTap:
        return _uiTapPlayer;
      case SoundId.toggle:
        return _togglePlayer;
      case SoundId.letter:
        return _letterPlayer;
      case SoundId.wordCorrect:
        return _wordCorrectPlayer;
      case SoundId.wordBonus:
        return _wordBonusPlayer;
      case SoundId.wordWrong:
        return _wordWrongPlayer;
      case SoundId.wordRepeat:
        return _wordRepeatPlayer;
      case SoundId.shuffle:
        return _shufflePlayer;
      case SoundId.hint:
        return _hintPlayer;
      case SoundId.target:
        return _targetPlayer;
      case SoundId.coin:
        return _coinPlayer;
      case SoundId.levelComplete:
        return _levelCompletePlayer;
      case SoundId.rewardClaim:
        return _rewardClaimPlayer;
      case SoundId.chapterUnlock:
        return _chapterUnlockPlayer;
      case SoundId.missionClaim:
        return _missionClaimPlayer;
    }
  }

  void dispose() {
    if (_listening) SettingsState.instance.removeListener(_onSettingsChanged);
    _disposed = true;
    _uiTapPlayer.dispose();
    _togglePlayer.dispose();
    _letterPlayer.dispose();
    _wordCorrectPlayer.dispose();
    _wordBonusPlayer.dispose();
    _wordWrongPlayer.dispose();
    _wordRepeatPlayer.dispose();
    _shufflePlayer.dispose();
    _hintPlayer.dispose();
    _targetPlayer.dispose();
    _coinPlayer.dispose();
    _levelCompletePlayer.dispose();
    _rewardClaimPlayer.dispose();
    _chapterUnlockPlayer.dispose();
    _missionClaimPlayer.dispose();
  }
}

/// Sound effect identifiers.
enum SoundId {
  uiTap,
  toggle,
  letter,
  wordCorrect,
  wordBonus,
  wordWrong,
  wordRepeat,
  shuffle,
  hint,
  target,
  coin,
  levelComplete,
  rewardClaim,
  chapterUnlock,
  missionClaim,
}