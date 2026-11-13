import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// UMP calls are wrapped so consent ordering can be tested without native SDKs.
abstract class AdConsentPlatform {
  Future<void> update();
  Future<void> showRequiredForm();
  Future<bool> canRequestAds();
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();
}

class _UmpPlatform implements AdConsentPlatform {
  @override
  Future<void> update() async {
    final result = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () { if (!result.isCompleted) result.complete(); },
      (error) { if (!result.isCompleted) result.completeError(StateError(error.message)); },
    );
    await result.future.timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> showRequiredForm() async {
    FormError? failure;
    await ConsentForm.loadAndShowConsentFormIfRequired((error) => failure = error);
    if (failure != null) throw StateError(failure!.message);
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() async {
    FormError? failure;
    await ConsentForm.showPrivacyOptionsForm((error) => failure = error);
    if (failure != null) throw StateError(failure!.message);
  }
}

/// Consent is refreshed once per app session before ad initialization. On
/// failure we fail closed and allow a later retry, even if UMP has cached data.
class AdConsentService extends ChangeNotifier {
  AdConsentService._() : _platform = _UmpPlatform();
  @visibleForTesting
  AdConsentService.withPlatform(this._platform);
  static final AdConsentService instance = AdConsentService._();

  final AdConsentPlatform _platform;
  bool _updatedThisSession = false;
  bool _busy = false;
  bool _privacyOptionsRequired = false;
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  bool get updatedThisSession => _updatedThisSession;
  bool get isBusy => _busy;

  Future<void> _refreshOptions() async {
    _privacyOptionsRequired = await _platform.privacyOptionsRequired();
    notifyListeners();
  }

  Future<bool> prepare({bool Function()? canShow}) async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      if (!_updatedThisSession) {
        await _platform.update();
        // The screen may have been closed while the network request ran.
        if (canShow != null && !canShow()) return false;
        await _refreshOptions();
        await _platform.showRequiredForm();
        await _refreshOptions();
        _updatedThisSession = true;
      }
      final permitted = await _platform.canRequestAds();
      if (!permitted) _updatedThisSession = false;
      return permitted;
    } catch (error) {
      debugPrint('Ad consent unavailable: $error');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Only shown after UMP says an entry point is required. Never overlap a
  /// consent update or another form; recheck consent before each later ad.
  Future<bool> showPrivacyOptions() async {
    if (_busy || !_privacyOptionsRequired) return false;
    _busy = true;
    notifyListeners();
    try {
      await _platform.showPrivacyOptions();
      await _refreshOptions();
      return true;
    } catch (error) {
      debugPrint('Ad privacy options unavailable: $error');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
