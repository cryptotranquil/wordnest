import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wordnest/src/config/ad_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  int _levelsCleared = 0;
  DateTime? _lastInterstitialTime;
  bool _removeAdsOwned = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  Future<void> preloadRewardedAd() async {
    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      _rewardedAd = null;
    }
  }

  Future<void> showRewardedAd({Function? onReward}) async {
    if (_rewardedAd == null) {
      await preloadRewardedAd();
      if (_rewardedAd == null) return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onReward?.call();
      },
    );
  }

  Future<void> preloadInterstitialAd() async {
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