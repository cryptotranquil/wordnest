import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordnest/src/services/music_service.dart';
import 'package:wordnest/src/state/settings_state.dart';

class FakeMusicPlayback implements MusicPlayback {
  final calls = <String>[];

  @override
  Future<void> setLoop() async => calls.add('loop');
  @override
  Future<void> setVolume(double volume) async => calls.add('volume:$volume');
  @override
  Future<void> playAsset(String path) async => calls.add('play:$path');
  @override
  Future<void> pause() async => calls.add('pause');
  @override
  Future<void> resume() async => calls.add('resume');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsState.instance.load();
  });

  test('web startup finishes without attempting playback before a gesture', () async {
    final playback = FakeMusicPlayback();
    final music = MusicService.forTesting(playback: playback, requiresGesture: true);
    await music.init();
    await music.playForChapter(0);
    expect(playback.calls, ['loop']);

    await music.onUserInteraction();
    expect(playback.calls, contains('play:audio/music/chapter_forest.mp3'));
    music.dispose();
  });

  test('a gesture before initialization is retained', () async {
    final playback = FakeMusicPlayback();
    final music = MusicService.forTesting(playback: playback, requiresGesture: true);
    await music.onUserInteraction();
    await music.playForChapter(1);
    await music.init();
    expect(playback.calls, contains('play:audio/music/chapter_ocean.mp3'));
    music.dispose();
  });

  test('gesture does not override mute or background state', () async {
    final playback = FakeMusicPlayback();
    final music = MusicService.forTesting(playback: playback, requiresGesture: true);
    SettingsState.instance.setMusicOn(false);
    await music.init();
    await music.playForChapter(2);
    await music.pause();
    await music.onUserInteraction();
    expect(playback.calls.where((call) => call.startsWith('play:')), isEmpty);

    SettingsState.instance.setMusicOn(true);
    await music.playForChapter(2); // Wait for the settings change in the queue.
    expect(playback.calls.where((call) => call.startsWith('play:')), isEmpty);
    await music.resume();
    expect(playback.calls, contains('play:audio/music/chapter_cosmos.mp3'));
    music.dispose();
  });

  test('native playback does not require a gesture', () async {
    final playback = FakeMusicPlayback();
    final music = MusicService.forTesting(playback: playback, requiresGesture: false);
    await music.init();
    await music.playForChapter(0);
    expect(playback.calls, contains('play:audio/music/chapter_forest.mp3'));
    music.dispose();
  });
}
