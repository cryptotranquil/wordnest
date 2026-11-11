import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordnest/src/screens/chapters_screen.dart';
import 'package:wordnest/src/screens/missions_screen.dart';
import 'package:wordnest/src/screens/settings_screen.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/state/settings_state.dart';
import 'package:wordnest/src/state/stats_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(Widget screen) => MaterialApp(theme: buildWordnestTheme(), home: screen);

  testWidgets('journey scrolls vertically and marks locked levels', (tester) async {
    await tester.pumpWidget(app(ChaptersScreen(player: PlayerState())));
    expect(find.text('Chapter 1  •  Whispering Forest'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Locked'), findsWidgets);
    final scrollable = find.byType(Scrollable).first;
    await tester.drag(scrollable, const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(find.text('Chapter 2  •  Ocean Serenity'), findsOneWidget);
    await tester.drag(scrollable, const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(find.text('Chapter 3  •  Celestial Cosmos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mission tabs show actual progress', (tester) async {
    final stats = StatsState();
    await tester.pumpWidget(app(MissionsScreen(player: PlayerState(), stats: stats)));
    expect(find.text('Find 10 bonus words'), findsOneWidget);
    expect(find.text('0 / 10'), findsOneWidget);
    await tester.tap(find.text('Achievements'));
    await tester.pump();
    expect(find.text('Lexicon Scholar 1'), findsOneWidget);
    expect(find.textContaining('Claim'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings controls update state and volume fits in the row', (tester) async {
    await SettingsState.instance.load();
    await tester.pumpWidget(app(const SettingsScreen()));
    expect(find.text('70%'), findsOneWidget);
    final switches = find.byType(Switch);
    await tester.tap(switches.first);
    await tester.pumpAndSettle();
    expect(SettingsState.instance.soundOn, isFalse);
    expect(tester.takeException(), isNull);
  });
}
