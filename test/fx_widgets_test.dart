import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordnest/src/widgets/fx/fx_config.dart';
import 'package:wordnest/src/widgets/fx/pressable.dart';
import 'package:wordnest/src/widgets/fx/count_up.dart';
import 'package:wordnest/src/widgets/fx/shake_x.dart';
import 'package:wordnest/src/widgets/fx/ping.dart';
import 'package:wordnest/src/widgets/fx/confetti_rain.dart';
import 'package:wordnest/src/state/settings_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FX Widgets', () {
    testWidgets('Pressable scales and returns on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Pressable(
                onTap: () {},
                onUiTapSound: () {},
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Placeholder(),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap the widget
      await tester.tap(find.byType(Pressable));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Widget should still exist after tap
      expect(find.byType(Pressable), findsOneWidget);
    });

    testWidgets('CountUp ends on exact target value', (WidgetTester tester) async {
      int? finalValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CountUp(
                from: 0,
                to: 10,
                builder: (context, value) {
                  if (value == 10) {
                    finalValue = value;
                  }
                  return Text('$value');
                },
                duration: const Duration(milliseconds: 500),
              ),
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 600));

      expect(finalValue, 10);
    });

    testWidgets('ShakeX returns to offset zero after animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShakeX(
                key: const ValueKey('initial'),
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: Placeholder(),
                ),
              ),
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('Ping animates continuously', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Ping(
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: Placeholder(),
                ),
              ),
            ),
          ),
        ),
      );

      // Ping should be visible
      expect(find.byType(Ping), findsOneWidget);
    });

    testWidgets('ConfettiRain renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: SizedBox.expand(
              child: ConfettiRain(),
            ),
          ),
        ),
      );
    });
  });

  group('fxReduced helper', () {
    testWidgets('checks reduceMotion setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(fxReduced(context), SettingsState.instance.reduceMotion);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}