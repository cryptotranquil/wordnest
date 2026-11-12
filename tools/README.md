# WordNest level generator

The generator checks every crossword and bonus word against the bundled
[ENABLE word-game dictionary](dictionaries/README.md), including when a custom
curated `--wordlist` is supplied. A curated list can narrow the dictionary but
cannot add words outside it. The dictionary covers ASCII words of 3–7 letters,
matching the generator's supported wheel sizes. `--dictionary path/to/list.txt`
can replace it with a different trusted word list (one word per line).

It writes both `assets/levels/levels.json` and
`lib/src/data/generated_levels.dart`. The app reads the generated Dart copy;
commit both files together. Generation works offline without extra packages;
`--common` additionally requires the `wordfreq` package.

## Check the shipped levels

```sh
python tools/generate_levels.py --validate assets/levels/levels.json
python -m unittest discover -s tools -p 'test_*.py'
flutter test
```

Validation checks dictionary membership for both grid and bonus words,
crossings, playable letters, grid runs, contiguous level numbers and duplicate
letter sets and grid-word sets. It does **not** check that words are familiar,
appropriate or fun. ENABLE contains obscure words, inflections and entries that
may look like names or abbreviations. The small blocklist and optional frequency
filter are not a substitute for human review and play-testing.

## Extend without changing existing puzzles

```sh
python -m pip install wordfreq==3.1.1
python tools/generate_levels.py --append --count 20 --common --min-zipf 4.5
```

`--append` validates the existing JSON, checks it matches the generated Dart
file, preserves all existing levels and starts at the next number. Previously
used letter sets and grid-word sets are excluded. If there are not enough valid,
unique puzzles, generation fails **without replacing the existing files**.
Do not run independent batches and merge them manually: only an append operation
can check uniqueness against the previous batch. The app currently defines only
three chapters (levels 1–60); extending the data alone does not add chapter UI.

## Replace the whole set deliberately

The current 60-level set was generated with Python 3, the bundled ENABLE subset,
[`wordfreq` 3.1.1](https://github.com/rspeer/wordfreq), and:

```sh
python tools/generate_levels.py --count 60 --common --min-zipf 4.5 --replace
```

`--replace` is required to overwrite existing outputs. It can change existing
puzzles even though saved level numbers remain the same. Keep the input files,
package version, seed and options identical for reproducible results. The
original WordNest prototype was replaced with the dictionary-checked set because
34 of its grids contained at least one word outside ENABLE; saved unlock progress
is not reset, but players replaying a level will see a new puzzle.
