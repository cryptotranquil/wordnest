# WordNest progress and next steps

## Implemented in this pass

- The existing Python generator now outputs a 60-level prototype and the matching
  Dart data consumed by the app. Levels advance sequentially; missing levels no
  longer silently open level 14. Generated words still need human review.
- Home shows the current chapter and real progress, opens the shop and Missions,
  and no longer advertises a nonexistent daily puzzle.
- Gameplay updates persistent daily and lifetime statistics. Four daily missions
  reset at local midnight, and achievements track bonus words, chapters and
  flawless completions. Rewards can be claimed once per day or achievement tier.
  Play time counts while a puzzle is open and the app is foregrounded.
- Player state now loads before entering the app. Legacy preferences are read
  when the new snapshot is absent. Existing players retain their current level;
  since the old demo jumped from 1 to 14, a player at 14 will see levels 2–13 as
  unlocked even though they did not play the new versions.
- Audio services initialize at startup, use the bundled paths, observe settings
  and app lifecycle, and select the track for the chapter being played. Music
  changes tracks directly rather than crossfading. Haptics now obey their toggle.
- A daily gift claim is saved and its coin animation no longer divides by zero.

## Validate on a device

Flutter and device audio were not available in the development sandbox. Run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Test completing and replaying puzzles, chapter transitions, mission claims across
restart and midnight, background/resume, the volume and mute switches, haptics,
and audio on both Android and iOS. Also test small screens and large text.

## Still to do before release

- Curate the word list and play-test every generated puzzle; generated words may
  include abbreviations, names or awkward vocabulary.
- Reminders are still marked coming soon: notification permission and scheduling
  have not been implemented. Verify privacy links and the purchase/ad flows.
- Review replay reward farming, anti-clock-change behavior, persistence failure
  handling, accessibility and release performance. Local preferences are not a
  secure economy or a substitute for a transactional server.
