# What is already implemented in WordNest (read this first)

Based on the last version of the project I reviewed. Verify against the real code before relying on it,
and trust the code over this list when they disagree. Do not rebuild anything marked DONE; extend it.

## Screens (lib/src/screens/)
| File | Status | Notes |
|---|---|---|
| splash_screen.dart | DONE | Loads state, then daily reward (if unclaimed), then AppShell |
| daily_reward_screen.dart | DONE | 7-day grid, claim button, `kShowDoubleReward` flag, reward table in data/daily_rewards.dart |
| app_shell.dart | DONE | Bottom bar: Home, Chapters, Missions, Settings (IndexedStack) |
| home_screen.dart | DONE | Check chapter text comes from ChapterBook, not hardcoded |
| gameplay_screen.dart | DONE | Real crossword + letter wheel + Hint/Target boosters; coin "+" opens Shop |
| level_complete_sheet.dart | DONE (plain) | Compare with Stitch level_complete design |
| tutorial_overlay.dart | DONE | |
| chapters_screen.dart | DONE (static) | Chapter cards + level path, driven by ChapterBook |
| shop_screen.dart | UI DONE | Purchases / ads may be partly stubbed |
| settings_screen.dart | UI DONE | Real behaviour depends on whether the audio/settings prompt was applied |
| missions_screen.dart | EXCLUDED | The owner will supply this screen later. DO NOT edit, restyle or animate it. Keep it compiling. |

## Widgets (lib/src/widgets/)
board.dart (PROTECTED, real crossword board), letter_wheel.dart, controls.dart (BoosterButton with token badge),
capsules.dart (CoinPill and other pills), scenic_background.dart, brand.dart, level_path_painter.dart,
today_panel.dart, app_metrics.dart

## State, data, services
- state/player_state.dart (persistent coins, tokens, progress), state/daily_reward_service.dart,
  state/game_controller.dart (PROTECTED), state/settings_state.dart, state/stats_state.dart
- data/levels.dart (PROTECTED; loads assets/levels/levels.json), data/chapter.dart (ChapterBook),
  data/daily_rewards.dart, data/missions.dart (EXCLUDED with the missions screen)
- models/level.dart (PROTECTED: Level, PlacedWord, GridCell)
- services/ad_service.dart, services/purchase_service.dart (may be partial)
- services/sound_service.dart, services/music_service.dart exist ONLY if the audio prompt was applied

## Theme
lib/src/theme/wordnest_theme.dart: AppColors (ink, cream, gold, teal ...), AppText helpers. Reuse them. Do not add colours or fonts.

## Known gaps (not part of this task)
Real AdMob and Google Play Billing, final level content review, the missions screen and its logic.
