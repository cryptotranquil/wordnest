import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordnest/src/screens/app_shell.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/state/settings_state.dart';
import 'package:wordnest/src/state/stats_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsState.instance.load();
    await StatsState.instance.load();
    SettingsState.instance.setSoundOn(false);
  });

  int selectedTab(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index!;

  Future<void> tapTab(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(ValueKey('navigation-tab-$index')));
    await tester.pump();
  }

  testWidgets('back walks through tabs and allows exit on home', (tester) async {
    final player = PlayerState();
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: AppShell(player: player)));
    expect(selectedTab(tester), 0);
    await tapTab(tester, 1);
    await tapTab(tester, 3);
    expect(selectedTab(tester), 3);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(selectedTab(tester), 1);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(selectedTab(tester), 0);
    expect(tester.widget<PopScope<void>>(find.byType(PopScope<void>).first).canPop, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    player.dispose();
  });

  testWidgets('back closes a pushed screen before changing tabs', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final player = PlayerState();
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(navigatorKey: key, home: AppShell(player: player)));
    await tapTab(tester, 3);
    key.currentState!.push(MaterialPageRoute<void>(builder: (_) =>
      const Scaffold(body: Text('A pushed screen'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('A pushed screen'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('A pushed screen'), findsNothing);
    expect(selectedTab(tester), 3);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(selectedTab(tester), 0);
    await tester.pumpWidget(const SizedBox.shrink());
    player.dispose();
  });
}
