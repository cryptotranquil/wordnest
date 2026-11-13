# WordNest

## Build an Android APK with GitHub Actions

The **Build Android APK** workflow runs on branch pushes and can also be started
manually from GitHub: open **Actions → Build Android APK → Run workflow**, select
the branch, and run it. When the run succeeds, open the run and download
**wordnest-android-test-apk** under Artifacts. Extract the ZIP and install
`app-release.apk` on an Android device. The workflow also launches the APK on an
Android 13 emulator and only uploads it if the startup check succeeds. A
ProGuard rule preserves WorkManager's database classes used during startup.

This is a release-mode **testing build**, not a store-ready release: the current
Android configuration signs it with a generated debug key. The key can differ
between workflow runs, so uninstalling a previous build may be necessary (and
will remove its local game data). The package ID is still `com.example.wordnest`.
Before distributing or publishing, configure a unique application ID and a
secure, persistent release signing key. The app uses Google test ad units by
default; see [rewarded ads setup](docs/rewarded_ads.md) for the explicit production
build flag and mandatory privacy, audience, consent and AdMob setup. No signing secrets are needed for this test workflow.
