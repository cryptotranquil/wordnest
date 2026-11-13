import 'package:flutter/foundation.dart';

/// Production ads require an explicit opt-in AND a release build. The normal
/// CI APK is release-mode but deliberately does not set this flag.
class AdConfig {
  static const bool productionAdsRequested =
      bool.fromEnvironment('WORDNEST_PRODUCTION_ADS', defaultValue: false);
  static const String androidProductionRewardedAdUnitId =
      'ca-app-pub-1956286249831581/7344915113';
  static const String androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  @visibleForTesting
  static String androidUnitFor({required bool release, required bool productionRequested}) =>
      release && productionRequested ? androidProductionRewardedAdUnitId : androidTestRewardedAdUnitId;

  static bool get useProductionAndroidAds =>
      kReleaseMode && productionAdsRequested && !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  static String get androidRewardedAdUnitId => androidUnitFor(
    release: kReleaseMode, productionRequested: productionAdsRequested,
  );

  // No production iOS unit has been supplied.
  static const String iosRewardedAdUnitId = iosTestRewardedAdUnitId;
}
