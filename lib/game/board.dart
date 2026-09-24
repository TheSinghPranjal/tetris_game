/// Cell bytes match the Android `CellConstants` plus locked block colors.
///
/// `0` is empty, `1` is the falling piece (ephemeral). Locked cells use the
/// block color bytes `2`–`6` from `Block.BlockColor`.
abstract final class Cell {
  static const int empty = 0;
  static const int ephemeral = 1;
}

/// 20×10 matrix and the row-shift line clear from `AppModel`.
class Board {
  Board()
    : cells = List<List<int>>.generate(
        rowCount,
        (_) => List<int>.filled(columnCount, Cell.empty),
        growable: false,
      );

  static const int columnCount = 10;
  static const int rowCount = 20;

  final List<List<int>> cells;

  void reset({bool ephemeralOnly = true}) {
    for (var row = 0; row < rowCount; row++) {
      for (var column = 0; column < columnCount; column++) {
        if (!ephemeralOnly || cells[row][column] == Cell.ephemeral) {
          cells[row][column] = Cell.empty;
        }
      }
    }
  }

  /// Same bounds and occupancy checks as `AppModel.validTranslation`.
  bool validTranslation(int x, int y, List<List<int>> shape) {
    if (y < 0 || x < 0) {
      return false;
    }
    if (y + shape.length > rowCount) {
      return false;
    }
    if (shape.isEmpty || x + shape.first.length > columnCount) {
      return false;
    }
    for (var i = 0; i < shape.length; i++) {
      for (var j = 0; j < shape[i].length; j++) {
        final occupied = shape[i][j] != Cell.empty;
        if (occupied && cells[y + i][x + j] != Cell.empty) {
          return false;
        }
      }
    }
    return true;
  }

  void translate(int x, int y, List<List<int>> shape) {
    for (var i = 0; i < shape.length; i++) {
      for (var j = 0; j < shape[i].length; j++) {
        if (shape[i][j] != Cell.empty) {
          cells[y + i][x + j] = shape[i][j];
        }
      }
    }
  }

  void persist(int colorByte) {
    for (var row = 0; row < rowCount; row++) {
      for (var column = 0; column < columnCount; column++) {
        if (cells[row][column] == Cell.ephemeral) {
          cells[row][column] = colorByte;
        }
      }
    }
  }

  /// Top-to-bottom full-row scan. A full row is removed with [shiftRows].
  int assess() {
    var cleared = 0;
    for (var row = 0; row < cells.length; row++) {
      var emptyCells = 0;
      for (var column = 0; column < cells[row].length; column++) {
        if (cells[row][column] == Cell.empty) {
          emptyCells++;
        }
      }
      if (emptyCells == 0) {
        shiftRows(row);
        cleared++;
      }
    }
    return cleared;
  }

  /// Copies every row above [nToRow] down by one and empties row 0.
  void shiftRows(int nToRow) {
    if (nToRow > 0) {
      for (var row = nToRow - 1; row >= 0; row--) {
        for (var column = 0; column < cells[row].length; column++) {
          cells[row + 1][column] = cells[row][column];
        }
      }
    }
    for (var column = 0; column < cells.first.length; column++) {
      cells[0][column] = Cell.empty;
    }
  }

  List<List<int>> copyCells() =>
      cells.map(List<int>.from).toList(growable: false);
}
