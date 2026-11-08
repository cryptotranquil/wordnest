/// A single crossword cell position on the level board.
class GridCell {
  const GridCell(this.row, this.col);

  final int row;
  final int col;

  String get key => '$row:$col';

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridCell($row, $col)';
}

/// A target word and the cells it occupies, either across or down.
class PlacedWord {
  const PlacedWord(this.word, this.cells);

  final String word;
  final List<GridCell> cells;

  bool get isAcross => cells.length > 1 && cells.first.row == cells.last.row;
}

/// Everything needed to play one level: wheel letters, the crossword and the
/// hidden words that feed the bonus jar.
class Level {
  Level({
    required this.number,
    required this.chapter,
    required this.letters,
    required this.words,
    required this.bonusWords,
    required this.rows,
    required this.cols,
  }) : _lettersByCell = _indexLetters(words);

  final int number;
  final String chapter;

  /// The six letters arranged on the wheel.
  final List<String> letters;

  final List<PlacedWord> words;
  final List<String> bonusWords;
  final int rows;
  final int cols;

  final Map<String, String> _lettersByCell;

  static Map<String, String> _indexLetters(List<PlacedWord> words) {
    final map = <String, String>{};
    for (final placed in words) {
      for (var i = 0; i < placed.cells.length; i++) {
        map[placed.cells[i].key] = placed.word[i];
      }
    }
    return map;
  }

  String? letterAt(GridCell cell) => _lettersByCell[cell.key];

  bool hasCell(GridCell cell) => _lettersByCell.containsKey(cell.key);

  PlacedWord? wordFor(String value) {
    final upper = value.toUpperCase();
    for (final placed in words) {
      if (placed.word == upper) return placed;
    }
    return null;
  }

  /// Every cell of the board, row by row, `null` where the shape has a hole.
  List<List<GridCell?>> get shape => <List<GridCell?>>[
        for (var row = 0; row < rows; row++)
          <GridCell?>[
            for (var col = 0; col < cols; col++)
              hasCell(GridCell(row, col)) ? GridCell(row, col) : null,
          ],
      ];

  int get totalCells => _lettersByCell.length;
}
