import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordnest/src/services/ad_consent_service.dart';

class FakeConsentPlatform implements AdConsentPlatform {
  final calls = <String>[];
  bool permitted = true;
  bool required = true;
  bool updateFails = false;
  bool formFails = false;
  Completer<void>? updateWait;

  @override
  Future<void> update() async {
    calls.add('update');
    if (updateFails) throw StateError('network failure');
    if (updateWait != null) await updateWait!.future;
  }
  @override
  Future<void> showRequiredForm() async {
    calls.add('form');
    if (formFails) throw StateError('form failure');
  }
  @override
  Future<bool> canRequestAds() async { calls.add('canRequest'); return permitted; }
  @override
  Future<bool> privacyOptionsRequired() async { calls.add('optionsRequired'); return required; }
  @override
  Future<void> showPrivacyOptions() async { calls.add('options'); }
}

void main() {
  test('updates and shows consent before checking ad permission', () async {
    final platform = FakeConsentPlatform();
    final consent = AdConsentService.withPlatform(platform);
    expect(await consent.prepare(), isTrue);
    expect(platform.calls, ['update', 'optionsRequired', 'form', 'optionsRequired', 'canRequest']);
    expect(consent.privacyOptionsRequired, isTrue);
    platform.calls.clear();
    expect(await consent.prepare(), isTrue);
    expect(platform.calls, ['canRequest']);
    consent.dispose();
  });

  test('errors and absent consent block ads and can be retried', () async {
    final platform = FakeConsentPlatform()..updateFails = true;
    final consent = AdConsentService.withPlatform(platform);
    expect(await consent.prepare(), isFalse);
    expect(platform.calls, ['update']);
    platform.updateFails = false;
    platform.formFails = true;
    expect(await consent.prepare(), isFalse);
    expect(platform.calls, isNot(contains('canRequest')));
    platform.formFails = false;
    platform.permitted = false;
    expect(await consent.prepare(), isFalse);
    platform.permitted = true;
    expect(await consent.prepare(), isTrue);
    consent.dispose();
  });

  test('does not display a late form after the offer is closed', () async {
    final platform = FakeConsentPlatform()..updateWait = Completer<void>();
    final consent = AdConsentService.withPlatform(platform);
    var visible = true;
    final first = consent.prepare(canShow: () => visible);
    expect(await consent.prepare(), isFalse);
    visible = false;
    platform.updateWait!.complete();
    expect(await first, isFalse);
    expect(platform.calls, ['update']);
    consent.dispose();
  });

  test('privacy options are available when required and consent is rechecked', () async {
    final platform = FakeConsentPlatform();
    final consent = AdConsentService.withPlatform(platform);
    expect(await consent.showPrivacyOptions(), isFalse);
    expect(await consent.prepare(), isTrue);
    expect(await consent.showPrivacyOptions(), isTrue);
    platform.permitted = false;
    expect(await consent.prepare(), isFalse);
    expect(platform.calls, contains('options'));
    consent.dispose();
  });
}
