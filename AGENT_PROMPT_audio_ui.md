Apply this package and implement the changes below. Work in the numbered parts, in order. After each part run
`flutter analyze` and `flutter test`, fix problems, give me a 5-line summary, then continue to the next part.
Do NOT rewrite or simplify existing game files. Protected: lib/src/models/level.dart, lib/src/widgets/board.dart,
lib/src/data/levels.dart. In lib/src/state/game_controller.dart you may change ONLY the shuffle() method.
Make the smallest edits that work. Report only what you actually ran. Do not say something works unless you verified it.

PART 0 - Files
Copy from the package into the project (same paths): assets/audio/ (sfx/ and music/ folders), tools/make_audio.py,
tools/generate_levels.py, tools/README.md. In pubspec.yaml add under the existing flutter assets (keep what is there):
    - assets/audio/sfx/
    - assets/audio/music/
Add packages: audioplayers, package_info_plus. Run flutter pub get.

PART 1 - Replace the word "Sanctuary" with "WordNest"
Search the whole project (lib, test, assets, tools; ignore design/, build/, .dart_tool/), case-insensitive.
  - Settings header pill "Sanctuary"            -> "WordNest"
  - "Sanctuary Codex"                           -> "WordNest Guide"
  - "Word Sanctuary v1.0.0"                     -> "WordNest v{version}" using package_info_plus (version + build)
  - "Sanctuary Shop" / "Sanctuary Perks"        -> "WordNest Shop" / "WordNest Perks"
  - splash "PREPARING YOUR SANCTUARY"           -> "PREPARING YOUR WORDNEST"
  - "...in sanctuary" / "of the sanctuary"      -> "...in WordNest"
  - Chapter name "Forest Sanctuary"             -> "Whispering Forest" everywhere: ChapterBook, every "chapter" value
    in assets/levels/levels.json, tools/generate_levels.py CHAPTERS.
  - "Sanctuary Dusk" row is replaced in Part 2.
Finish with a case-insensitive search for "sanctuary" in lib, test, assets, tools. It must find nothing.

PART 2 - Settings that really work
1. Create ONE shared SettingsState in app.dart, load it during the splash, and pass it to the settings screen (and to the
   sound/music services). SettingsScreen must NOT create its own SettingsState. Use ListenableBuilder so every
   toggle and the slider update immediately and persist (shared_preferences).
2. Rows: Sound Effects (toggle), Ambient Harmonics (toggle, music), Music Volume slider, Tactile Pulse (toggle; all
   HapticFeedback calls in gameplay/letter wheel go through one helper that checks hapticsOn).
3. Replace the "Sanctuary Dusk" toggle with "Reduce Motion" (new persisted setting reduceMotion; used by the shuffle
   animation and any confetti/particles; also true if MediaQuery.disableAnimations).
4. "Word Lexicon": opens a bottom sheet showing "English (US)" selected and "More languages coming soon".
5. "How to Play": opens the existing TutorialOverlay.
6. "Wellness Reminders": opens a bottom sheet with an on/off switch and a time picker (showTimePicker); save hour and
   minute (add reminderMinute). Subtitle shows "Daily 8:00 PM" or "Off". Schedule a daily local notification
   with flutter_local_notifications on Android only (request notification permission when switching on). On web or
   when scheduling is not available, only save the setting and show a SnackBar "Reminders work on the phone app".
   If notification setup is complicated, save the setting, skip scheduling, and tell me clearly.
7. "Privacy & Terms": open the URL from a const in lib/src/config/app_links.dart (placeholder). If it cannot be opened
   show a SnackBar. Never throw.
8. Every row is tappable (InkWell, at least 48dp high) and plays the ui tap sound (Part 3).

PART 3 - Sound effects (lib/src/services/sound_service.dart)
Use audioplayers. enum SoundId { uiTap, toggle, letter, wordCorrect, wordBonus, wordWrong, wordRepeat, shuffle, hint, target,
coin, levelComplete, rewardClaim, chapterUnlock, missionClaim }, mapped to assets/audio/sfx/<name>.mp3
(ui_tap, toggle, letter_1..letter_7, word_correct, word_bonus, word_wrong, word_repeat, shuffle, hint, target, coin,
level_complete, reward_claim, chapter_unlock, mission_claim). Low-latency players (a small pool), respects soundOn,
never throws (catch everything), works on web. API: play(SoundId), playLetter(positionInSwipe) which plays letter_1..7
(clamped), stepping down when the swipe goes back.
Hook up: each letter picked on the wheel (letter_N by its position in the swipe), word accepted / bonus word /
wrong word / already-found word, shuffle, hint, target, coin credit, level complete, daily reward claim,
mission and achievement claim, chapter unlock, bottom-nav taps, Play button, settings rows.

PART 4 - Chapter music (lib/src/services/music_service.dart)
Tracks: chapter_forest.mp3, chapter_ocean.mp3, chapter_cosmos.mp3 in assets/audio/music/. Track for a chapter =
(chapterIndex % 3): forest, ocean, cosmos. API: playForChapter(int chapterIndex), pause(), resume().
Behaviour:
  - Plays on Home, Chapters, Missions and Gameplay for the player's current chapter. Same chapter = keep playing
    (never restart when moving between screens). New chapter = crossfade over 2 seconds.
  - Loop without a gap: use two AudioPlayers and crossfade (about 3 s) near the end of each play-through
    instead of ReleaseMode.loop (MP3 loops leave a small gap).
  - Volume = settings.musicVolume * 0.8; musicOn off = fade out over 400 ms, on = fade in. Lower to about 50% while
    levelComplete / rewardClaim / chapterUnlock sounds play.
  - Pause when the app goes to the background and resume when it returns (WidgetsBindingObserver).
  - On web, browsers block autoplay: start the music on the first user tap. Catch all errors silently.

PART 5 - Letter shuffle animation
1. GameController.shuffle(): replace the one-step rotation with a real random shuffle of _wheelOrder that is guaranteed
   to differ from the current order when there are 2+ letters. Update any test that expected a rotation.
2. LetterWheel (lib/src/widgets/letter_wheel.dart): give each letter a stable id (its original index, pass the
   controller's wheelOrder) so duplicate letters (two Es) animate correctly. When the order changes, every letter
   travels along the circle from its old slot to its new slot (angle interpolation, not a straight line),
   520 ms, Curves.easeInOutCubic, with a small stagger (30 ms per letter) and a slight scale dip (1.0 to 0.9 to 1.0).
   The shuffle button icon spins 360 degrees over the same time. Clear the current swipe first and ignore touches
   while animating. If reduceMotion is on, jump straight to the new order. Play SoundId.shuffle on each shuffle.
   Use one AnimationController, not many AnimatedPositioned widgets.

FINAL
Run flutter analyze and flutter test. Run the app in Chrome: check settings toggles, the shuffle animation, and that
no sound or music error appears in the console. List what works, what you could not verify, and anything stubbed.
