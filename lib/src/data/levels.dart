import '../models/level.dart';

/// Handcrafted levels. Every across and down run is a real word, so the
/// crossword reads correctly whichever way a word is solved.
abstract final class LevelBook {
  /// Order the "Next level" action walks through.
  static const List<int> order = <int>[1, 14, 15];

  static final Map<int, Level> _levels = <int, Level>{
    1: Level(
      number: 1,
      chapter: 'First Light',
      letters: const <String>['T', 'I', 'M', 'E', 'R', 'B'],
      words: <PlacedWord>[
        PlacedWord('TIME', _across(0, 0, 'TIME')),
        PlacedWord('TIER', _down(0, 0, 'TIER')),
      ],
      bonusWords: const <String>['TIRE', 'RITE', 'MITE', 'EMIT', 'MERIT'],
      rows: 4,
      cols: 4,
    ),
    14: Level(
      number: 14,
      chapter: 'Misty Lake',
      letters: const <String>['T', 'I', 'M', 'B', 'E', 'R'],
      words: <PlacedWord>[
        PlacedWord('TIMBER', _across(0, 0, 'TIMBER')),
        PlacedWord('TRIBE', _down(0, 0, 'TRIBE')),
        PlacedWord('MERIT', _down(0, 2, 'MERIT')),
        PlacedWord('EMIT', _down(0, 4, 'EMIT')),
      ],
      bonusWords: const <String>['BITER', 'TIMER', 'MITER', 'BRIM', 'RIME'],
      rows: 5,
      cols: 6,
    ),
    15: Level(
      number: 15,
      chapter: 'Misty Lake',
      letters: const <String>['S', 'T', 'A', 'R', 'E', 'L'],
      words: <PlacedWord>[
        PlacedWord('STARE', _across(0, 0, 'STARE')),
        PlacedWord('SLATE', _down(0, 0, 'SLATE')),
        PlacedWord('ART', _down(0, 2, 'ART')),
      ],
      bonusWords: const <String>['LATER', 'TEARS', 'LASER', 'SEAL', 'STAR'],
      rows: 5,
      cols: 5,
    ),
  };

  static Level level(int number) => _levels[number] ?? _levels[14]!;

  static int levelCount(int number) => _levels.length;

  /// Every level, sorted by number (used by the validation tests).
  static List<Level> get all =>
      _levels.values.toList()..sort((a, b) => a.number.compareTo(b.number));

  static int? nextLevelAfter(int number) {
    final index = order.indexOf(number);
    if (index < 0 || index + 1 >= order.length) return null;
    return order[index + 1];
  }

  static List<GridCell> _across(int row, int col, String word) => <GridCell>[
        for (var i = 0; i < word.length; i++) GridCell(row, col + i),
      ];

  static List<GridCell> _down(int row, int col, String word) => <GridCell>[
        for (var i = 0; i < word.length; i++) GridCell(row + i, col),
      ];
}
