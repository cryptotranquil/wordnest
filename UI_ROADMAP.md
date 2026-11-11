# WordNest: UI and next steps

## Step 1 — UI pass

- Chapters now shows a single vertical, winding path for the three 20-level chapters. Tap a current or cleared puzzle to play it; unavailable levels are labelled **Coming soon**.
- Missions uses the cleaner card and tab layout. Progress, reset timing and claim buttons are deliberately not simulated: the tracking and reward system still needs to be built.
- Settings follows the grouped reference layout with persistent switches and a volume slider. Reminders are marked as coming soon rather than pretending to schedule notifications.
- The shared navigation uses the reference's teal selected state and accommodates the device's bottom safe area.

## Important before testing

The code currently contains only three actual puzzles: levels 1, 14 and 15. Completing level 1 advances directly to 14. The other 57 chapter nodes are a roadmap, not playable levels. `LevelBook.level()` currently falls back to level 14 for missing numbers; the journey avoids opening those missing puzzles. The level generator documentation describes a JSON loader that the current code does not actually use.

Run on a device or emulator with the Flutter SDK required by `pubspec.yaml`:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Check the three screens at small and large text sizes, scroll through all chapters, try the tabs and switches, and play/replay an available level.

## Recommended order after UI approval

1. **Functionality:** implement daily reset, persistent mission progress and one-time claims; connect real achievements and notification scheduling. Audit settings so each toggle affects the corresponding behavior.
2. **Gameplay and levels:** make level loading and progression consistent, populate and validate all 60 puzzles, test the replay progression guard, boosters and rewards (including whether replays should pay coins). Replace hardcoded chapter and progress text on Home.
3. **Chapter themes:** switch gameplay scenery and music according to the selected level's chapter and verify unlock boundaries.
4. **Audio:** initialize and connect the existing audio services, check asset paths, mute/volume behavior, lifecycle handling and transitions on physical devices. Audio assets and services exist, but their presence alone does not prove playback works.
5. **Release checks:** verify privacy links, purchases/ads, accessibility, persistence across restarts and device performance.
