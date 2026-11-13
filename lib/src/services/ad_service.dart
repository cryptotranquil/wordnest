import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wordnest/src/config/ad_config.dart';
import 'package:wordnest/src/services/ad_consent_service.dart';

/// Result of one opted-in rewarded ad. Rewards are delivered separately, only
/// from the SDK's onUserEarnedReward callback.
enum RewardedAdResult {
  rewarded, dismissed, unavailable, unsupported, busy, failed, privacySetupRequired
}

class _ConsentNotReady implements Exception {
  const _ConsentNotReady();
}

abstract class RewardedAdGateway {
  bool get isSupported;
  bool get needsAdultConfirmation;
  bool get adsBlockedForAge;
  void recordAdultConfirmation(bool isAdult);
  Future<RewardedAdResult> showRewardedAd({required VoidCallback onReward, bool Function()? canShow});
}

/// Small interfaces keep the ad lifecycle testable without the native SDK.
abstract class RewardedAdBackend {
  bool get isSupported;
  Future<RewardedAdHandle?> load({bool Function()? canShow});
}

abstract class RewardedAdHandle {
  Future<RewardedAdResult> show({required VoidCallback onReward});
  Future<void> dispose();
}

class AdService implements RewardedAdGateway {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal() : _rewardedBackend = _MobileRewardedAdBackend();

  @visibleForTesting
  AdService.withRewardedBackend(RewardedAdBackend backend) : _rewardedBackend = backend;

  final RewardedAdBackend _rewardedBackend;
  bool _rewardedBusy = false;
  // Session-only age response: do not collect or persist birth dates.
  bool? _isAdult;
  InterstitialAd? _interstitialAd;
  int _levelsCleared = 0;
  DateTime? _lastInterstitialTime;
  bool _removeAdsOwned = false;

  @override
  bool get isSupported => _rewardedBackend.isSupported;

  @override
  bool get needsAdultConfirmation => AdConfig.useProductionAndroidAds && _isAdult == null;

  @override
  bool get adsBlockedForAge => AdConfig.useProductionAndroidAds && _isAdult == false;

  @override
  void recordAdultConfirmation(bool isAdult) => _isAdult = isAdult;

  @override
  Future<RewardedAdResult> showRewardedAd({required VoidCallback onReward, bool Function()? canShow}) async {
    if (!isSupported) return RewardedAdResult.unsupported;
    // Avoid requesting production ads for users who may be below the age of
    // consent; the game itself remains playable for teenagers without ads.
    if (AdConfig.useProductionAndroidAds && _isAdult != true) {
      return RewardedAdResult.privacySetupRequired;
    }
    if (_rewardedBusy) return RewardedAdResult.busy;
    _rewardedBusy = true;
    var credited = false;
    try {
      final ad = await _rewardedBackend.load(canShow: canShow);
      if (ad == null) return RewardedAdResult.unavailable;
      if (canShow != null && !canShow()) {
        await ad.dispose();
        return RewardedAdResult.dismissed;
      }
      return await ad.show(onReward: () {
        if (credited) return;
        credited = true;
        onReward();
      });
    } on _ConsentNotReady {
      return RewardedAdResult.privacySetupRequired;
    } catch (error) {
      debugPrint('Rewarded ad failed: $error');
      return RewardedAdResult.failed;
    } finally {
      _rewardedBusy = false;
    }
  }

  Future<void> preloadInterstitialAd() async {
    if (!isSupported || (AdConfig.useProductionAndroidAds && _isAdult != true)) return;
    if (!await AdConsentService.instance.prepare()) return;
    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      _interstitialAd = null;
    }
  }

  Future<void> showInterstitialAd() async {
    if (_removeAdsOwned) return;
    if (_levelsCleared < 3 || _levelsCleared < 4) return;
    if (_lastInterstitialTime != null &&
        DateTime.now().difference(_lastInterstitialTime!).inMinutes < 3) {
      return;
    }

    if (_interstitialAd == null) {
      await preloadInterstitialAd();
      if (_interstitialAd == null) return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastInterstitialTime = DateTime.now();
        preloadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
  }

  void incrementLevelsCleared() {
    _levelsCleared++;
  }

  void resetLevelsCleared() {
    _levelsCleared = 0;
  }

  void setRemoveAdsOwned(bool owned) {
    _removeAdsOwned = owned;
  }
}
/// AdMob rewarded ads are supported by this plugin only on Android and iOS.
class _MobileRewardedAdBackend implements RewardedAdBackend {
  Future<void>? _initialization;

  @override
  bool get isSupported => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() async {
    try {
      _initialization ??= MobileAds.instance.initialize().then<void>((_) {});
      await _initialization!.timeout(const Duration(seconds: 15));
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<RewardedAdHandle?> load({bool Function()? canShow}) async {
    final id = defaultTargetPlatform == TargetPlatform.iOS
        ? AdConfig.iosRewardedAdUnitId : AdConfig.androidRewardedAdUnitId;
    if (!await AdConsentService.instance.prepare(canShow: canShow)) {
      throw const _ConsentNotReady();
    }
    if (canShow != null && !canShow()) return null;
    await _initialize();
    final loaded = Completer<RewardedAd?>();

    Future<void> requestAd() async {
      try {
        await RewardedAd.load(
          adUnitId: id,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              // A delayed callback after a timeout must not leak a native ad.
              if (loaded.isCompleted) {
                ad.dispose();
              } else {
                loaded.complete(ad);
              }
            },
            onAdFailedToLoad: (error) {
              debugPrint('Rewarded ad unavailable: $error');
              if (!loaded.isCompleted) loaded.complete(null);
            },
          ),
        );
      } catch (error) {
        debugPrint('Rewarded ad request failed: $error');
        if (!loaded.isCompleted) loaded.complete(null);
      }
    }

    unawaited(requestAd());
    final ad = await loaded.future.timeout(const Duration(seconds: 20), onTimeout: () {
      if (!loaded.isCompleted) loaded.complete(null);
      return null;
    });
    return ad == null ? null : _MobileRewardedAdHandle(ad);
  }
}

class _MobileRewardedAdHandle implements RewardedAdHandle {
  _MobileRewardedAdHandle(this.ad);
  final RewardedAd ad;

  @override
  Future<void> dispose() => ad.dispose();

  @override
  Future<RewardedAdResult> show({required VoidCallback onReward}) async {
    final completed = Completer<RewardedAdResult>();
    var earned = false;
    var dismissed = false;
    var disposed = false;
    Timer? dismissalTimer;

    void finish(RewardedAdResult result) {
      dismissalTimer?.cancel();
      if (!disposed) {
        disposed = true;
        ad.dispose();
      }
      if (!completed.isCompleted) completed.complete(result);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (_) {
        dismissed = true;
        if (earned) {
          finish(RewardedAdResult.rewarded);
        } else {
          // Some ad networks deliver the earned callback just after dismissal.
          dismissalTimer = Timer(const Duration(seconds: 2), () => finish(
            earned ? RewardedAdResult.rewarded : RewardedAdResult.dismissed,
          ));
        }
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('Rewarded ad could not be shown: $error');
        finish(RewardedAdResult.failed);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, reward) {
        if (earned) return;
        earned = true;
        onReward();
        if (dismissed) finish(RewardedAdResult.rewarded);
      });
    } catch (error) {
      debugPrint('Rewarded ad could not be shown: $error');
      finish(RewardedAdResult.failed);
    }
    return completed.future;
  }
}
