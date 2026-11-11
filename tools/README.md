# WordNest level generator

`generate_levels.py` produces both `assets/levels/levels.json` for inspection
and `lib/src/data/generated_levels.dart` for the app. Commit both files together;
the app reads the generated Dart copy synchronously, not the JSON asset.

The checked-in 60-level prototype was made with Python 3 and [`wordfreq` 3.1.1](https://github.com/rspeer/wordfreq) (Apache-2.0):

```sh
python -m pip install wordfreq==3.1.1
python tools/generate_levels.py --count 60 --common --min-zipf 3.3
python tools/generate_levels.py --validate assets/levels/levels.json --common --min-zipf 3.3
python -m unittest discover -s tools -p 'test_*.py'
flutter test
```

For a curated dictionary, use `--wordlist path/to/words.txt` (one English word
per line) or `--dictionary path/to/words.txt --common`. The same input, version,
seed and options produce the same output. The default seed is 2024. Keep the
same input and options when extending a shipped set; changing them will change
existing puzzles and can affect saved progress. Generation does not overwrite
existing output if it cannot build the requested number of levels.

**Before release:** structural validation checks crossings, playable letters,
grid runs and duplicates. It does not guarantee appropriate vocabulary or fun
difficulty. The current automatically generated set can contain names,
abbreviations and obscure words; curate the source list, expand the blocklist,
and play-test every level. The app ships only the generated bonus words, not a
full dictionary. Generated chapter names repeat after 60, but the current app
only defines three chapter themes and paths.
