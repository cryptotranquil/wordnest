import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordnest/src/services/ad_service.dart';
import 'package:wordnest/src/config/ad_config.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/widgets/rewarded_offers.dart';

class FakeHandle implements RewardedAdHandle {
  final result = Completer<RewardedAdResult>();
  VoidCallback? reward;
  bool disposed = false;
  @override
  Future<void> dispose() async { disposed = true; }
  @override
  Future<RewardedAdResult> show({required VoidCallback onReward}) {
    reward = onReward;
    return result.future;
  }
}

class FakeBackend implements RewardedAdBackend {
  FakeBackend({this.supported = true, this.handle});
  final bool supported;
  final FakeHandle? handle;
  int loads = 0;
  @override
  bool get isSupported => supported;
  @override
  Future<RewardedAdHandle?> load({bool Function()? canShow}) async { loads++; return handle; }
}


class DelayedBackend implements RewardedAdBackend {
  final pending = Completer<RewardedAdHandle?>();
  @override
  bool get isSupported => true;
  @override
  Future<RewardedAdHandle?> load({bool Function()? canShow}) => pending.future;
}

class FakeGateway implements RewardedAdGateway {
  FakeGateway({this.supported = true, this.requireAge = false});
  final bool supported;
  final bool requireAge;
  bool? adult;
  Completer<RewardedAdResult>? pending;
  VoidCallback? reward;
  @override
  bool get isSupported => supported;
  @override
  bool get needsAdultConfirmation => requireAge && adult == null;
  @override
  bool get adsBlockedForAge => requireAge && adult == false;
  @override
  void recordAdultConfirmation(bool isAdult) { adult = isAdult; }
  @override
  Future<RewardedAdResult> showRewardedAd({required VoidCallback onReward, bool Function()? canShow}) {
    reward = onReward;
    pending = Completer<RewardedAdResult>();
    return pending!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('production units require both release mode and explicit opt-in', () {
    expect(AdConfig.androidUnitFor(release: false, productionRequested: true), AdConfig.androidTestRewardedAdUnitId);
    expect(AdConfig.androidUnitFor(release: true, productionRequested: false), AdConfig.androidTestRewardedAdUnitId);
    expect(AdConfig.androidUnitFor(release: true, productionRequested: true), AdConfig.androidProductionRewardedAdUnitId);
  });

  test('service rejects overlapping ads and awards only once per ad', () async {
    final handle = FakeHandle();
    final backend = FakeBackend(handle: handle);
    final service = AdService.withRewardedBackend(backend);
    var rewards = 0;
    final first = service.showRewardedAd(onReward: () => rewards++);
    await Future<void>.delayed(Duration.zero);
    expect(await service.showRewardedAd(onReward: () => rewards++), RewardedAdResult.busy);
    handle.reward!();
    handle.reward!();
    handle.result.complete(RewardedAdResult.rewarded);
    expect(await first, RewardedAdResult.rewarded);
    expect(rewards, 1);
    expect(backend.loads, 1);
  });

  test('an ad is not shown if its offer was closed during loading', () async {
    final backend = DelayedBackend();
    final service = AdService.withRewardedBackend(backend);
    var stillVisible = true;
    var rewards = 0;
    final result = service.showRewardedAd(onReward: () => rewards++, canShow: () => stillVisible);
    stillVisible = false;
    final handle = FakeHandle();
    backend.pending.complete(handle);
    expect(await result, RewardedAdResult.dismissed);
    expect(handle.disposed, isTrue);
    expect(handle.reward, isNull);
    expect(rewards, 0);
  });

  test('unsupported and unavailable ads never reward the player', () async {
    var rewards = 0;
    final unsupported = FakeBackend(supported: false);
    expect(await AdService.withRewardedBackend(unsupported).showRewardedAd(onReward: () => rewards++), RewardedAdResult.unsupported);
    expect(unsupported.loads, 0);
    expect(await AdService.withRewardedBackend(FakeBackend()).showRewardedAd(onReward: () => rewards++), RewardedAdResult.unavailable);
    expect(rewards, 0);
  });

  Widget buildOffers(PlayerState player, RewardedAdGateway ads) =>
      MaterialApp(home: Scaffold(body: RewardedOffers(player: player, ads: ads)));

  testWidgets('completed ads award one hint or 100 coins, once and persistently', (tester) async {
    final player = PlayerState();
    final ads = FakeGateway();
    await tester.pumpWidget(buildOffers(player, ads));
    expect(find.text('Watch one ad for 1 hint'), findsOneWidget);
    expect(find.text('Watch one ad for 100 coins'), findsOneWidget);

    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNull);
    ads.reward!();
    ads.reward!();
    ads.pending!.complete(RewardedAdResult.rewarded);
    await tester.pump();
    expect(player.hints, 1);
    expect(player.coins, 0);

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    ads.reward!();
    ads.reward!();
    ads.pending!.complete(RewardedAdResult.rewarded);
    await tester.pump();
    expect(player.hints, 1);
    expect(player.coins, 100);
    await player.save();
    final reloaded = PlayerState();
    await reloaded.load();
    expect(reloaded.hints, 1);
    expect(reloaded.coins, 100);
  });

  testWidgets('closed or failed ads do not grant rewards', (tester) async {
    final player = PlayerState();
    final ads = FakeGateway();
    await tester.pumpWidget(buildOffers(player, ads));
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    ads.pending!.complete(RewardedAdResult.dismissed);
    await tester.pump();
    expect(player.hints, 0);
    expect(find.text('Ad closed before the reward was earned.'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    ads.pending!.complete(RewardedAdResult.failed);
    await tester.pump();
    expect(player.coins, 0);
  });

  testWidgets('earned reward is credited even if the offer was closed', (tester) async {
    final player = PlayerState();
    final ads = FakeGateway();
    await tester.pumpWidget(buildOffers(player, ads));
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    ads.reward!();
    ads.pending!.complete(RewardedAdResult.rewarded);
    await tester.pump();
    expect(player.coins, 100);
    await player.save();
  });

  testWidgets('under-18 players cannot start production ads', (tester) async {
    final player = PlayerState();
    final ads = FakeGateway(requireAge: true);
    await tester.pumpWidget(buildOffers(player, ads));
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Under 18'));
    await tester.pumpAndSettle();
    expect(ads.pending, isNull);
    expect(player.hints, 0);
    expect(find.textContaining('Ads are unavailable for players under 18'), findsOneWidget);
  });

  testWidgets('adult confirmation proceeds to the ad, not an automatic reward', (tester) async {
    final player = PlayerState();
    final ads = FakeGateway(requireAge: true);
    await tester.pumpWidget(buildOffers(player, ads));
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('18 or older'));
    await tester.pump();
    expect(ads.pending, isNotNull);
    expect(player.coins, 0);
    ads.pending!.complete(RewardedAdResult.dismissed);
    await tester.pump();
    expect(player.coins, 0);
  });

  testWidgets('unsupported devices show a clear message and disabled buttons', (tester) async {
    await tester.pumpWidget(buildOffers(PlayerState(), FakeGateway(supported: false)));
    expect(find.textContaining('not in the browser'), findsOneWidget);
    for (final button in tester.widgetList<FilledButton>(find.byType(FilledButton))) {
      expect(button.onPressed, isNull);
    }
  });
}
