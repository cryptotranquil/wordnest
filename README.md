# WordNest

## Build an Android APK with GitHub Actions

The **Build Android APK** workflow runs on branch pushes and can also be started
manually from GitHub: open **Actions → Build Android APK → Run workflow**, select
 the branch, and run it. When the run succeeds, open the run and download
**wordnest-android-test-apk** under Artifacts. Extract the ZIP and install
`app-release.apk` on an Android device.

This is a release-mode **testing build**, not a store-ready release: the current
Android configuration signs it with a generated debug key. The key can differ
between workflow runs, so uninstalling a previous build may be necessary (and
will remove its local game data). The package ID is still `com.example.wordnest`.
Before distributing or publishing, configure a unique application ID and a
secure, persistent release signing key. The app also uses Google test ad IDs;
see [rewarded ads setup](docs/rewarded_ads.md) for production IDs and privacy
requirements. No signing secrets are needed for this test workflow.
