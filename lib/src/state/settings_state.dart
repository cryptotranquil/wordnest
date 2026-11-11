import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global settings state for WordNest.
/// Provides a shared instance that can be accessed from anywhere.
class SettingsState extends ChangeNotifier {
  SettingsState._();

  /// The global singleton instance of SettingsState.
  /// Use SettingsState.instance to access settings.
  static final SettingsState instance = SettingsState._();

  static const String _soundOnKey = 'soundOn';
  static const String _musicOnKey = 'musicOn';
  static const String _musicVolumeKey = 'musicVolume';
  static const String _hapticsOnKey = 'hapticsOn';
  static const String _reminderEnabledKey = 'reminderEnabled';
  static const String _reminderHourKey = 'reminderHour';
  static const String _reminderMinuteKey = 'reminderMinute';
  static const String _reduceMotionKey = 'reduceMotion';

  bool _soundOn = true;
  bool _musicOn = true;
  double _musicVolume = 0.7;
  bool _hapticsOn = true;
  bool _reminderEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _reduceMotion = false;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Private constructor for singleton - use instance getter

  static Future<void> initialize() async {
    await instance.load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundOn = prefs.getBool(_soundOnKey) ?? true;
    _musicOn = prefs.getBool(_musicOnKey) ?? true;
    _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.7;
    _hapticsOn = prefs.getBool(_hapticsOnKey) ?? true;
    _reminderEnabled = prefs.getBool(_reminderEnabledKey) ?? false;
    _reminderHour = prefs.getInt(_reminderHourKey) ?? 20;
    _reminderMinute = prefs.getInt(_reminderMinuteKey) ?? 0;
    _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    notifyListeners();
  }

  Future<void> loadFromPrefs() async {
    await load();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundOnKey, _soundOn);
    await prefs.setBool(_musicOnKey, _musicOn);
    await prefs.setDouble(_musicVolumeKey, _musicVolume);
    await prefs.setBool(_hapticsOnKey, _hapticsOn);
    await prefs.setBool(_reminderEnabledKey, _reminderEnabled);
    await prefs.setInt(_reminderHourKey, _reminderHour);
    await prefs.setInt(_reminderMinuteKey, _reminderMinute);
    await prefs.setBool(_reduceMotionKey, _reduceMotion);
  }

  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  double get musicVolume => _musicVolume;
  bool get hapticsOn => _hapticsOn;
  bool get reminderEnabled => _reminderEnabled;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get reduceMotion => _reduceMotion;

  void setSoundOn(bool value) {
    _soundOn = value;
    save();
    notifyListeners();
  }

  void setMusicOn(bool value) {
    _musicOn = value;
    save();
    notifyListeners();
  }

  void setMusicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    save();
    notifyListeners();
  }

  void setHapticsOn(bool value) {
    _hapticsOn = value;
    save();
    notifyListeners();
  }

  void setReminderEnabled(bool value) {
    _reminderEnabled = value;
    save();
    notifyListeners();
  }

  void setReminderHour(int value) {
    _reminderHour = value.clamp(0, 23);
    save();
    notifyListeners();
  }

  void setReminderMinute(int value) {
    _reminderMinute = value.clamp(0, 59);
    save();
    notifyListeners();
  }

  void setReduceMotion(bool value) {
    _reduceMotion = value;
    save();
    notifyListeners();
  }
}

/// Helper to trigger haptic feedback with settings awareness.
class HapticHelper {
  static void lightImpact() {
    if (SettingsState.instance.hapticsOn) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (SettingsState.instance.hapticsOn) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact() {
    if (SettingsState.instance.hapticsOn) {
      HapticFeedback.heavyImpact();
    }
  }

  static void selectionClick() {
    if (SettingsState.instance.hapticsOn) {
      HapticFeedback.selectionClick();
    }
  }
}