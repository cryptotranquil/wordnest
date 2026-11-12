# Rewarded ads

Players can choose to watch one ad for **1 hint** or one ad for **100 coins**.
Both options appear in the shop and when a player can't afford a hint or target.
The optional ad never spends coins, and rewards are credited only when the SDK
reports `onUserEarnedReward`; dismissals, load failures and unavailable ads do
not grant anything. One ad can only grant its chosen reward once. The Remove Ads
option is intended to remove interruptive ads, not these opt-in rewards.

## Testing

The checked-in Android and iOS app IDs and rewarded unit IDs are Google's sample
**test IDs**. They show test ads and generate no revenue. Rewarded ads require an
Android or iOS device/emulator with network access; the Google Mobile Ads Flutter
plugin does not support rewarded ads on web or desktop. Those platforms show an
explanation instead of a fake reward. Run `flutter test`, then test each offer on
a phone: complete an ad, close an ad without earning, disconnect the network,
restart the app to check the balance, and try again after a failure.

## Before publishing

1. Create the Android and iOS apps and rewarded units in AdMob. Replace the
   sample `com.google.android.gms.ads.APPLICATION_ID` in the Android manifest
   and `GADApplicationIdentifier` in `ios/Runner/Info.plist` with the matching
   real app IDs. Configure platform-specific rewarded unit IDs at build time via
   `--dart-define=ADMOB_ANDROID_REWARDED_AD_UNIT_ID=...` and
   `--dart-define=ADMOB_IOS_REWARDED_AD_UNIT_ID=...`. Use Google's test IDs on
   development devices; never test by clicking production ads.
2. Implement and verify required privacy consent (including an appropriate CMP
   where required), ad disclosures, age/child-directed settings, and platform
   privacy requirements **before requesting production ads**. This project does
   not yet implement a consent flow. Verify the AdMob policies applicable to your
   audience and regions, including Apple tracking requirements if applicable.
3. Verify ad fill, callback ordering, rewards, orientation, app lifecycle and
   platform setup on real Android and iOS devices. Consider server-side reward
   verification and a durable backend if the economy needs fraud protection.
   The current balance is stored locally and is not tamper-proof.

The shop's in-app purchase functionality is separate and still requires its own
store setup, validation and testing; this change does not make purchases ready
for release.
