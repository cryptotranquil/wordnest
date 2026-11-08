ROLE
You are polishing the Flutter game "WordNest" (this project). Do the whole job below in one go, without asking me
questions, unless something blocks you completely. Read IMPLEMENTED.md first: it lists what already exists. Reuse it,
do not rebuild it. Design references are in design/stitch/<screen>/screen.png + code.html (visual and motion
reference only; rebuild in Flutter with the existing theme: AppColors, AppText, Glass, CoinPill, ScenicBackground).
Never copy the HTML, never add web fonts or new colours, never embed the PNGs as the UI.

STYLE: RICH animation: bounces, particles, confetti, glows, flying coins. Fun but calm; never frantic, never blocking input.
Stitch's own motion is the baseline (animate-pulse on flame/dots/glows, animate-bounce on the "+25" chip, the
"Current Puzzle" bubble and coin icon, animate-ping on notification dots and the today tile, animate-spin on loaders, a
"floatDown" falling particle layer on Level Complete, 150-700 ms transitions). Keep those and add the extras below.

RULES (important, a previous run broke the game by replacing real code with placeholders)
1. PROTECTED, do not rewrite or simplify: lib/src/models/level.dart, lib/src/widgets/board.dart (you may wrap it or
   add animation layers around it, but keep its logic and look), lib/src/data/levels.dart, assets/levels/levels.json.
   lib/src/state/game_controller.dart: do not change game logic. Prefer reading existing state and diffing it in the
   screen. If you truly need a notifier/event there, add the smallest possible one and tell me exactly what.
2. EXCLUDED: lib/src/screens/missions_screen.dart and lib/src/data/missions.dart. I will provide that screen later. Do not
   edit, restyle or animate it. Just keep it compiling.
3. No placeholders. No text like "Board Widget", no empty handlers, no `return true` tests. Every animation below must
   really run in the app.
4. If SoundService / MusicService already exist (see IMPLEMENTED.md), call them at the listed moments. If they do not
   exist, do not create them in this task.
5. Search the project (lib, test, assets, tools; ignore design/) for "sanctuary" (case-insensitive). It must not appear in any
   text the player sees; use "WordNest".
6. After each PART run `flutter analyze` and `flutter test`, fix everything, then continue to the next part. Do not stop
   to ask for approval between parts.

PART 0 - FX toolkit (build once, reuse everywhere): lib/src/widgets/fx/
Small, tested, dependency-free widgets using only the Flutter SDK (AnimationController, TweenAnimationBuilder,
CustomPainter). No new packages.
- fx_config.dart: `bool fxReduced(BuildContext)` = SettingsState.reduceMotion (if that field exists) OR
  MediaQuery.disableAnimations. When true: no particles/confetti/loops; use 150 ms fades only.
- Pressable: press = scale to 0.96 (90 ms) and back with a small overshoot; optional haptic and ui tap sound.
- Pop: scale-in 0 to 1 with an overshoot (Curves.elasticOut or easeOutBack), configurable delay.
- StaggeredEntrance(index, step 60 ms): fade + rise 16 px.
- ShakeX: damped horizontal shake, 4 oscillations, about 320 ms, triggered by a changing key/value.
- CountUp: animates an int from a to b (ease-out, default 800 ms) with a builder.
- Breathing glow (color, period 1.6-2.4 s loop), Float (bob +-3 px, 3 s loop), Ping (expanding fading ring loop),
  ShimmerSweep (diagonal light sweep every 3 s).
- ParticleBurst: 12-24 small sparkle/coin/star particles with gravity from a point, 600-900 ms.
- ConfettiRain: full-screen, max 60 pieces (cream, gold, teal), falls and sways, about 2.5 s, plays once.
- FlyToTarget: sprites (coins, a chip) travel from a source GlobalKey to a target GlobalKey along a curved arc,
  500-700 ms, 60 ms stagger, optional on-arrival callback (to bump a counter).
- FxAnchors: GlobalKeys for the coin pill and the Bonus Words pill so FlyToTarget can find them.
Performance: RepaintBoundary around particle layers, no setState of whole screens per frame, dispose every controller,
cap particles, one overlay at a time per effect type.

PART 1 - Playing screen (gameplay_screen.dart, letter_wheel.dart, board wrapper)
First compare the screen with design/stitch/word_sanctuary_main_gameplay_6_letter_wheel/screen.png and fix any visual
differences you find (spacing, tile size, pill styles, wheel size, booster buttons, preview strip). Keep the "Level N"
wording and the existing back/close action. Then verify the core behaviour really works and fix it if not: submitting a
grid word fills its tiles; a valid bonus word counts toward the Bonus Words pill; wrong and repeat words are rejected;
Hint reveals a letter (free token first, otherwise coins); Target highlights cells; finishing the last word opens the
Level Complete sheet; progress is saved. Then add the animation:
1. Level start: grid tiles enter with a stagger (fade + rise, 25 ms each); wheel letters pop in around the circle
   (50 ms stagger); Hint/Target buttons slide up.
2. Picking letters: the chosen wheel node scales to 1.12 with a soft glow; the ribbon follows (keep it); each letter in
   the preview strip pops in (scale 0.6 to 1, back-out).
3. Correct word: the word's tiles flip/pop in sequence (60 ms stagger, scale 0 to 1.15 to 1, elastic), a gold glow
   passes over the word, a small ParticleBurst at the last tile. Tiles that were already filled by a crossing do not
   re-animate.
4. Wrong word: the preview strip does ShakeX and tints soft coral for 300 ms, then the letters fade; nodes deselect.
5. Already-found word: that word on the grid pulses gold once.
6. Bonus word: the typed letters become a chip that flies (FlyToTarget) to the Bonus Words pill; the pill bounces,
   the count ticks up, a small sparkle burst at the pill. Reaching the full count adds a bigger burst.
7. Hint: the bulb icon pulses, the revealed tile flips open with a sparkle, the coin pill counts down with a floating
   "-100". Target: a radar ping ring expands from the booster and the highlighted cells pulse twice.
8. Shuffle: if not already done, letters travel along the circle to their new slots (520 ms, easeInOutCubic, 30 ms
   stagger, slight scale dip), the shuffle icon spins 360 degrees, input is ignored while it plays. GameController.shuffle()
   must be a real random shuffle that always changes the order (this one method may be edited); duplicate letters
   must animate correctly (use stable ids, not letters).
9. Last word found: a wave runs over all tiles (40 ms per column), ConfettiRain starts, and the Level Complete sheet
   slides up after about 900 ms.
10. Coin pill everywhere: balance changes count up/down (CountUp) and the coin icon gives one small bounce.

PART 2 - Rewards: Level Complete and Daily Reward
Compare level_complete_sheet.dart with design/stitch/word_sanctuary_level_complete/screen.png (badge, title, three stars
Speed / Mastery / Lexicon, Coins Rewarded row, Secret Words Vault progress, Words Found, Precision, Next Level, Replay,
Share). Make it match, using real values from the game (stars earned, coins, bonus words, words found, precision),
then animate:
1. Sheet slides up with a spring (about 600 ms, slight overshoot) over a dimmed backdrop; ConfettiRain behind it
   once; a light falling-particle layer like Stitch's floatDown.
2. The badge pops with a small rotation wobble; the title fades up.
3. Stars appear one after another (350 ms apart): scale 0 to 1.3 to 1, rotation -15 to 0, sparkle burst on earned
   stars; unearned stars just fade in dim.
4. Coins Rewarded: the number counts up to its value (800 ms) while the coin icon spins; then 6-10 coins FlyToTarget to the
   top coin pill, the "+25" chip bounces (Stitch animate-bounce) and the pill total counts up.
5. Secret Words Vault bar fills from 0 with ease-out (700 ms) with a shimmer; if completed, a +50 coin burst.
   Words Found and Precision count up.
6. Next Level button: slow ShimmerSweep and gentle breathing glow, Pressable. Replay/Share: Pressable.
Daily Reward screen (daily_reward_screen.dart, design/stitch/word_sanctuary_daily_login_reward):
1. Card scales in 0.92 to 1 with a fade; day tiles stagger in (60 ms).
2. Today tile: breathing gold glow + Ping; the "TODAY" tag bounces; the streak flame pulses/flickers (Stitch animate-pulse).
3. Newly claimed days show their check with a pop. Day 7 chest floats gently and has twinkling sparkles.
4. Claim: Pressable; the today tile shakes then bursts (ParticleBurst); reward icons fly to the coin pill
   (FlyToTarget); coins count up; the button turns into a checkmark "Collected!". Day 7 adds ConfettiRain.

PART 3 - Shop (shop_screen.dart, design/stitch/word_sanctuary_shop)
1. Cards enter with a stagger (slide up + fade, 80 ms). All cards are Pressable.
2. Best Value pack: ShimmerSweep on its badge every 3 s and a breathing glow; coin/pouch/chest icons Float.
3. Zen Focus Clip: play icon pulses; the "1 / 3" charge pips pop when they fill; the refresh timer text ticks live.
4. Remove All Ads: the three check chips pop in one by one when the screen opens.
5. Purchase success (with the fake or real service): coin shower (ParticleBurst + FlyToTarget to the coin pill),
   balance counts up, a check icon pops in the confirmation. A loading state uses the spinning icon (Stitch "Calming...").
6. The header coin pill pulses whenever the balance changes.

PART 4 - Chapters map (chapters_screen.dart, level_path_painter.dart, design/stitch/word_sanctuary_chapters)
1. The scenic header image drifts slowly (about +-6 px over 12 s, ken-burns).
2. On open, the dashed path draws itself progressively from the first node to the current one (900 ms) and the nodes
   pop in along it (70 ms stagger); cleared nodes twinkle their stars once. The list auto-scrolls smoothly to the
   current node (700 ms, easeInOut).
3. Current node: pulsing ring (Ping), gentle Float, and the "Current Puzzle - Tap to Play" bubble bounces (Stitch
   animate-bounce). Tapping it: Pressable, then a 350 ms zoom/fade transition into the gameplay screen.
4. Locked nodes: tap = small ShakeX + a snackbar "Clear level N to unlock".
5. A node that just unlocked (after finishing a level): lock icon wobbles, bursts open with a ParticleBurst, turns into a
   numbered node. Completed chapter card: stars shimmer. Chapter cards expand/collapse with AnimatedSize (300 ms).

PART 5 - Global polish
1. One shared page transition for all routes (fade + 24 px slide, 250 ms).
2. Bottom bar: the selected icon bounces (scale 1 to 1.2 to 1) and its label glow fades in.
3. All tappable cards/buttons in the screens above use Pressable.
4. OPTIONAL, do last, small (delete this part if you disagree): Settings toggles animate their thumb and track colour
   (200 ms) and rows use Pressable; Home Play button has a soft breathing glow and the twinkling dots from the Stitch
   home design.

TESTS
Add widget tests for the FX toolkit (Pressable scales and returns, CountUp ends on the exact value, ShakeX returns to 0,
reduce-motion disables particles) and keep all existing tests passing. flutter analyze must report no issues.

PERFORMANCE AND ACCESSIBILITY
Target 60 fps on a mid-range phone. No animation may block input longer than 600 ms. Respect reduce motion everywhere.
Never run more than one confetti or burst overlay of the same type at once.

FINAL REPORT (required)
Run flutter analyze, flutter test, and run the app (Chrome is fine for visuals). Then list, per item in Parts 1 to 5:
DONE / NOT DONE, the file(s) changed, and how you verified it. State clearly anything you could not verify. Do not claim
something works unless you ran it.
