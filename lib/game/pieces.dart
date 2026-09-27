/// The seven guideline tetrominoes. Each type has its own color byte.
enum PieceType {
  i(colorByte: 2, boxSize: 4),
  o(colorByte: 3, boxSize: 2),
  t(colorByte: 4, boxSize: 3),
  s(colorByte: 5, boxSize: 3),
  z(colorByte: 6, boxSize: 3),
  j(colorByte: 7, boxSize: 3),
  l(colorByte: 8, boxSize: 3);

  const PieceType({required this.colorByte, required this.boxSize});

  /// Value written into the board when this piece locks.
  final int colorByte;

  /// Side of the square rotation box used by SRS.
  final int boxSize;
}

/// A cell offset inside a piece's rotation box.
typedef CellOffset = ({int row, int col});

/// Spawn orientation (state 0) of each piece, in SRS layout.
const Map<PieceType, List<CellOffset>> _spawnCells =
    <PieceType, List<CellOffset>>{
      PieceType.i: [
        (row: 1, col: 0),
        (row: 1, col: 1),
        (row: 1, col: 2),
        (row: 1, col: 3),
      ],
      PieceType.o: [
        (row: 0, col: 0),
        (row: 0, col: 1),
        (row: 1, col: 0),
        (row: 1, col: 1),
      ],
      PieceType.t: [
        (row: 0, col: 1),
        (row: 1, col: 0),
        (row: 1, col: 1),
        (row: 1, col: 2),
      ],
      PieceType.s: [
        (row: 0, col: 1),
        (row: 0, col: 2),
        (row: 1, col: 0),
        (row: 1, col: 1),
      ],
      PieceType.z: [
        (row: 0, col: 0),
        (row: 0, col: 1),
        (row: 1, col: 1),
        (row: 1, col: 2),
      ],
      PieceType.j: [
        (row: 0, col: 0),
        (row: 1, col: 0),
        (row: 1, col: 1),
        (row: 1, col: 2),
      ],
      PieceType.l: [
        (row: 0, col: 2),
        (row: 1, col: 0),
        (row: 1, col: 1),
        (row: 1, col: 2),
      ],
    };

/// All four rotation states, built by turning the spawn state clockwise
/// inside the rotation box.
final Map<PieceType, List<List<CellOffset>>> _rotations = {
  for (final type in PieceType.values) type: _buildRotations(type),
};

List<List<CellOffset>> _buildRotations(PieceType type) {
  final states = <List<CellOffset>>[_spawnCells[type]!];
  for (var i = 1; i < 4; i++) {
    final previous = states.last;
    states.add(
      type == PieceType.o
          ? previous
          : [
              for (final cell in previous)
                (row: cell.col, col: type.boxSize - 1 - cell.row),
            ],
    );
  }
  return states;
}

/// Cells of [type] in rotation [state] (0 spawn, 1 R, 2 180, 3 L).
List<CellOffset> cellsOf(PieceType type, int state) =>
    _rotations[type]![state % 4];

/// SRS wall kicks as (dx, dy) with x right and y up, per `from*4+to`.
const Map<int, List<(int, int)>> _jlstzKicks = {
  0 * 4 + 1: [(0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2)],
  1 * 4 + 0: [(0, 0), (1, 0), (1, -1), (0, 2), (1, 2)],
  1 * 4 + 2: [(0, 0), (1, 0), (1, -1), (0, 2), (1, 2)],
  2 * 4 + 1: [(0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2)],
  2 * 4 + 3: [(0, 0), (1, 0), (1, 1), (0, -2), (1, -2)],
  3 * 4 + 2: [(0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2)],
  3 * 4 + 0: [(0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2)],
  0 * 4 + 3: [(0, 0), (1, 0), (1, 1), (0, -2), (1, -2)],
};

const Map<int, List<(int, int)>> _iKicks = {
  0 * 4 + 1: [(0, 0), (-2, 0), (1, 0), (-2, -1), (1, 2)],
  1 * 4 + 0: [(0, 0), (2, 0), (-1, 0), (2, 1), (-1, -2)],
  1 * 4 + 2: [(0, 0), (-1, 0), (2, 0), (-1, 2), (2, -1)],
  2 * 4 + 1: [(0, 0), (1, 0), (-2, 0), (1, -2), (-2, 1)],
  2 * 4 + 3: [(0, 0), (2, 0), (-1, 0), (2, 1), (-1, -2)],
  3 * 4 + 2: [(0, 0), (-2, 0), (1, 0), (-2, -1), (1, 2)],
  3 * 4 + 0: [(0, 0), (1, 0), (-2, 0), (1, -2), (-2, 1)],
  0 * 4 + 3: [(0, 0), (-1, 0), (2, 0), (-1, 2), (2, -1)],
};

/// Kick candidates for turning [type] from state [from] to [to], converted
/// to board deltas (column, row) where rows grow downward.
List<({int dx, int dy})> kicksFor(PieceType type, int from, int to) {
  if (type == PieceType.o) {
    return const [(dx: 0, dy: 0)];
  }
  final table = type == PieceType.i ? _iKicks : _jlstzKicks;
  return [for (final (x, y) in table[from * 4 + to]!) (dx: x, dy: -y)];
}

/// A live piece: the top-left of its rotation box is at ([x], [y]).
class Piece {
  const Piece({
    required this.type,
    required this.rotation,
    required this.x,
    required this.y,
  });

  /// Guideline spawn: centered, left-biased, top rows of the well.
  factory Piece.spawn(PieceType type, {required int columns}) {
    final width = type == PieceType.o ? 2 : type.boxSize;
    return Piece(
      type: type,
      rotation: 0,
      x: (columns - width) ~/ 2,
      y: type == PieceType.i ? -1 : 0,
    );
  }

  final PieceType type;
  final int rotation;
  final int x;
  final int y;

  int get colorByte => type.colorByte;

  /// Absolute board cells (row, col) this piece covers.
  Iterable<CellOffset> get cells sync* {
    for (final cell in cellsOf(type, rotation)) {
      yield (row: y + cell.row, col: x + cell.col);
    }
  }

  Piece copyWith({int? rotation, int? x, int? y}) {
    return Piece(
      type: type,
      rotation: rotation ?? this.rotation,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

/// Spawn-state shape of [type] as a tight 0/colorByte matrix, for previews.
List<List<int>> previewMatrix(PieceType type) {
  final cells = cellsOf(type, 0);
  final minRow = cells.map((c) => c.row).reduce((a, b) => a < b ? a : b);
  final maxRow = cells.map((c) => c.row).reduce((a, b) => a > b ? a : b);
  final minCol = cells.map((c) => c.col).reduce((a, b) => a < b ? a : b);
  final maxCol = cells.map((c) => c.col).reduce((a, b) => a > b ? a : b);
  final matrix = List.generate(
    maxRow - minRow + 1,
    (_) => List<int>.filled(maxCol - minCol + 1, 0),
  );
  for (final cell in cells) {
    matrix[cell.row - minRow][cell.col - minCol] = type.colorByte;
  }
  return matrix;
}

/// 7-bag randomizer: every run of seven pieces contains each type once.
class PieceBag {
  PieceBag(this._nextInt);

  final int Function(int max) _nextInt;
  final List<PieceType> _bag = <PieceType>[];

  PieceType next() {
    if (_bag.isEmpty) {
      _bag.addAll(PieceType.values);
      // Fisher–Yates shuffle.
      for (var i = _bag.length - 1; i > 0; i--) {
        final j = _nextInt(i + 1);
        final tmp = _bag[i];
        _bag[i] = _bag[j];
        _bag[j] = tmp;
      }
    }
    return _bag.removeAt(0);
  }
}
