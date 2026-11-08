# WordNest level generator

`generate_levels.py` builds the levels. The app only loads the JSON file it writes
(`assets/levels/levels.json`), so the game itself stays small and fast.

## 1. Get a word list
* **Dictionary (what counts as a valid word):** use a public-domain list such as ENABLE
  (`enable1.txt`, one word per line).
* **Common words only (recommended, so players don't meet obscure words):**
  `pip install wordfreq` and add `--common`. `--min-zipf 3.0` is the cutoff
  (raise it for easier words, lower it for more words).
* Extend `BLOCKLIST` in the script with any words you don't want in the game.

## 2. Generate
```
python tools/generate_levels.py --count 500 --dictionary enable1.txt --common --out assets/levels/levels.json
```
* Same `--seed` + same word list = same levels, so results are reproducible.
* Want more later? Run again with a bigger `--count`. Numbers always start at 1, so the
  first levels stay the same and players keep their progress.
* Difficulty ramps inside each chapter of 20 levels (wheel 4 to 6 letters, 3 to 9 words).
  Chapters cycle Forest, Ocean, Cosmos, then "II" versions. Change `plan()` to tune.

## 3. Check
```
python tools/generate_levels.py --validate assets/levels/levels.json --dictionary enable1.txt --common
flutter test          # test/level_validation_test.dart runs the same checks
```

## What the checks guarantee
Every word sits inside the board, crossings agree, every word (and bonus word) can be
built from the wheel with the right letter counts, there are no duplicates, and no
accidental words are formed by touching letters.

## Honest limits
* It guarantees valid *words from your list*, not good *taste*. Play a sample of levels.
* `assets/levels/levels.json` in this zip was made from a tiny demo list (288 words) just to
  test the app. Replace it with a real run before release.
* "Infinite": the script can make thousands of levels, shipped inside the app or added in an
  update. Generating truly endless levels on the phone would mean porting the script to Dart.
