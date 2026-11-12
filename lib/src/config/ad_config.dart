/// Google's sample IDs are used by default. Test ads do not generate revenue.
/// Supply production rewarded unit IDs using --dart-define after configuring
/// the matching Android/iOS AdMob app IDs and required privacy consent.
class AdConfig {
  static const String androidRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const String iosRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
}
