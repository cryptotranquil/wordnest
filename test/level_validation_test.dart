import 'package:flutter_test/flutter_test.dart';
import 'package:wordnest/src/data/levels.dart';
import 'package:wordnest/src/models/level.dart';

/// True when [word] can be spelled from [wheel], respecting letter counts.
bool canBuild(String word, List<String> wheel) {
  final pool = <String, int>{};
  for (final l in wheel) {
    pool[l] = (pool[l] ?? 0) + 1;
  }
  for (final ch in word.split('')) {
    final left = pool[ch] ?? 0;
    if (left == 0) return false;
    pool[ch] = left - 1;
  }
  return true;
}

void main() {
  final levels = LevelBook.all;

  test('there is at least one level and numbers are unique', () {
    expect(levels, isNotEmpty);
    expect(levels.map((l) => l.number).toSet().length, levels.length);
  });

  for (final level in levels) {
    group('Level ${level.number}', () {
      test('every word has one cell per letter, inside the grid', () {
        for (final placed in level.words) {
          expect(placed.cells.length, placed.word.length,
              reason: '${placed.word} cell count');
          for (final cell in placed.cells) {
            expect(cell.row >= 0 && cell.row < level.rows, isTrue,
                reason: '${placed.word} row ${cell.row} outside grid');
            expect(cell.col >= 0 && cell.col < level.cols, isTrue,
                reason: '${placed.word} col ${cell.col} outside grid');
          }
        }
      });

      test('crossings agree on letters', () {
        final seen = <String, String>{};
        for (final placed in level.words) {
          for (var i = 0; i < placed.cells.length; i++) {
            final key = placed.cells[i].key;
            final letter = placed.word[i];
            if (seen.containsKey(key)) {
              expect(seen[key], letter,
                  reason: 'cell $key has two different letters');
            }
            seen[key] = letter;
          }
        }
      });

      test('words are straight lines (across or down)', () {
        for (final placed in level.words) {
          final rows = placed.cells.map((c) => c.row).toSet();
          final cols = placed.cells.map((c) => c.col).toSet();
          expect(rows.length == 1 || cols.length == 1, isTrue,
              reason: '${placed.word} is not straight');
        }
      });

      test('every grid word and bonus word can be built from the wheel', () {
        for (final w in [
          ...level.words.map((p) => p.word),
          ...level.bonusWords,
        ]) {
          expect(canBuild(w, level.letters), isTrue,
              reason: '$w cannot be built from ${level.letters.join()}');
        }
      });

      test('no duplicate words; bonus words are not grid words', () {
        final grid = level.words.map((p) => p.word).toList();
        expect(grid.toSet().length, grid.length, reason: 'duplicate grid word');
        expect(level.bonusWords.toSet().length, level.bonusWords.length,
            reason: 'duplicate bonus word');
        for (final b in level.bonusWords) {
          expect(grid.contains(b), isFalse, reason: '$b is also a grid word');
        }
      });

      test('no accidental runs: touching letters only form listed words', () {
        final grid = level.words.map((p) => p.word).toSet();
        bool has(int r, int c) => level.hasCell(GridCell(r, c));
        String? at(int r, int c) => level.letterAt(GridCell(r, c));

        for (var r = 0; r < level.rows; r++) {
          var c = 0;
          while (c < level.cols) {
            if (!has(r, c)) {
              c++;
              continue;
            }
            final start = c;
            final b = StringBuffer();
            while (c < level.cols && has(r, c)) {
              b.write(at(r, c));
              c++;
            }
            if (c - start > 1) {
              expect(grid.contains(b.toString()), isTrue,
                  reason: 'across run "${b.toString()}" is not a grid word');
            }
          }
        }
        for (var c = 0; c < level.cols; c++) {
          var r = 0;
          while (r < level.rows) {
            if (!has(r, c)) {
              r++;
              continue;
            }
            final start = r;
            final b = StringBuffer();
            while (r < level.rows && has(r, c)) {
              b.write(at(r, c));
              r++;
            }
            if (r - start > 1) {
              expect(grid.contains(b.toString()), isTrue,
                  reason: 'down run "${b.toString()}" is not a grid word');
            }
          }
        }
      });
    });
  }
}
