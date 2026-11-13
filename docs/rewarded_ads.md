# Rewarded ads

Players choose to watch an ad for **1 hint** or **100 coins**, from the shop or
when they can't afford a hint or target. Rewards are granted only on the SDK's
earned-reward callback, once per ad. An unavailable, failed or closed ad does
not award anything.

## Production versus test builds

The Android manifest contains WordNest's AdMob app ID
`ca-app-pub-1956286249831581~6829909796`. The production rewarded unit is
`ca-app-pub-1956286249831581/7344915113`; it serves both rewards. To avoid
accidental live ad requests, **normal builds and GitHub Actions APKs use Google's
sample test ad unit** and do not earn money. Debug builds always use the sample
even if the production flag is supplied. iOS remains on Google's sample app and
unit IDs; a separate iOS AdMob app and unit are required for production.

A deliberately opted-in Android release build selects the real unit:

```sh
flutter build appbundle --release --dart-define=WORDNEST_PRODUCTION_ADS=true
# Or, for a deliberately opted-in APK:
flutter build apk --release --dart-define=WORDNEST_PRODUCTION_ADS=true
```

**Do not release or personally test live ads yet.** The current signing config
uses an ephemeral debug key and `com.example.wordnest`; replace these before a
store release. Configure test devices when checking a live unit; never click your
own live ads. The existing GitHub Actions workflow does not set the production
flag. User approval of live ads is not a substitute for verifying policy, privacy,
consent, account and store requirements.

## Consent and intended audience

The owner selected a worldwide audience of teenagers and adults. For the
production Android unit, the app asks users to self-declare whether they are 18
or older before starting ads or showing ad privacy forms. Users who say they are
under 18 can continue to play but cannot request ads in that session. This is a
conservative restriction, not reliable age verification; no birth date is stored.
Before release, have the owner review this approach and all age-related settings
against applicable laws, AdMob and store rules in every target country. Do not
market this configuration to children. If the intended audience changes, revisit
this design before showing any ads to minors.

For eligible players, Google UMP updates consent information once per session,
shows its required form before the app explicitly initializes the ad SDK or
requests an ad, and verifies `canRequestAds` before each ad. If UMP fails or
cannot request ads, ads are unavailable and the player can retry. Settings has
an **Ad privacy options** entry point. UMP cannot create or publish messages for
you: in AdMob **Privacy & messaging**, configure and publish the appropriate
messages, including a Google-certified CMP where required. Review privacy and
consent requirements, including applicable US state and EEA/UK/Switzerland
requirements, with appropriate legal advice. UMP alone is not proof of compliance.

The existing `https://wordnest.com/privacy` link is a placeholder and must be
replaced with the owner's actual, publicly accessible privacy policy. Complete
AdMob payment setup, app review and store linking, and satisfy applicable store
data-safety disclosures. Earnings and ad fill are not guaranteed.

## Validation checklist

- Use Google's test rewarded unit and UMP test devices/debug geography to test
  the EEA, regulated US state, and other relevant flows: new user, consent,
  refusal, no network, repeated attempts, restart, and changing privacy choices.
- Confirm an under-18 response never calls UMP or loads ads in production mode.
- Test both rewards, dismissal, concurrent attempts, unavailable ads, leaving the
  screen while loading, balance persistence, and consent changes on real devices.
- Consider server-side verification and a durable backend for fraud protection;
  the current local balance is not tamper-proof.

Rewarded ads are supported on Android and iOS, not web or desktop. In-app
purchases require separate store setup, validation and end-to-end testing.
