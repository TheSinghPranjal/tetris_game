import 'pieces.dart';

/// Cell values. `0` is empty; locked cells hold the piece's color byte.
abstract final class Cell {
  static const int empty = 0;
}

/// 20×10 well. Rows above the top (negative indexes) count as open space so
/// pieces can spawn and rotate partly out of view, as in guideline Tetris.
class Board {
  Board() : cells = List<List<int>>.generate(rowCount, (_) => _emptyRow());

  static const int columnCount = 10;
  static const int rowCount = 20;

  final List<List<int>> cells;

  static List<int> _emptyRow() => List<int>.filled(columnCount, Cell.empty);

  void clear() {
    for (final row in cells) {
      row.fillRange(0, columnCount, Cell.empty);
    }
  }

  bool isOpen(int row, int col) {
    if (col < 0 || col >= columnCount || row >= rowCount) {
      return false;
    }
    return row < 0 || cells[row][col] == Cell.empty;
  }

  bool fits(Piece piece) =>
      piece.cells.every((cell) => isOpen(cell.row, cell.col));

  /// Writes [piece] into the well. Returns false if any cell sits above the
  /// visible top (a lock out, which ends the game).
  bool lock(Piece piece) {
    var visible = true;
    for (final cell in piece.cells) {
      if (cell.row < 0) {
        visible = false;
        continue;
      }
      cells[cell.row][cell.col] = piece.colorByte;
    }
    return visible;
  }

  /// Removes every full row, drops the stack, and returns how many cleared.
  int clearFullRows() {
    var cleared = 0;
    for (var row = rowCount - 1; row >= 0;) {
      if (cells[row].every((cell) => cell != Cell.empty)) {
        cells.removeAt(row);
        cells.insert(0, _emptyRow());
        cleared++;
        // Re-check the same index: the row above has moved into it.
      } else {
        row--;
      }
    }
    return cleared;
  }

  List<List<int>> copyCells() =>
      cells.map(List<int>.of).toList(growable: false);
}
