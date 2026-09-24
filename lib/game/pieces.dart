import 'board.dart';

/// One tetromino, with the frames and horizontal spawn offset from `Shape`.
class Tetromino {
  const Tetromino({required this.startPosition, required this.frames});

  /// Subtracted from `columns / 2` when the piece is created.
  final int startPosition;
  final List<List<List<int>>> frames;

  int get frameCount => frames.length;
}

/// The seven shapes in `Shape.kt`, in enum order.
const List<Tetromino> tetrominoes = <Tetromino>[
  Tetromino(
    startPosition: 1,
    frames: <List<List<int>>>[
      [
        [1, 1],
        [1, 1],
      ],
    ],
  ),
  Tetromino(
    startPosition: 1,
    frames: <List<List<int>>>[
      [
        [1, 1, 0],
        [0, 1, 1],
      ],
      [
        [0, 1],
        [1, 1],
        [1, 0],
      ],
    ],
  ),
  Tetromino(
    startPosition: 1,
    frames: <List<List<int>>>[
      [
        [0, 1, 1],
        [1, 1, 0],
      ],
      [
        [1, 0],
        [1, 1],
        [0, 1],
      ],
    ],
  ),
  Tetromino(
    startPosition: 2,
    frames: <List<List<int>>>[
      [
        [1, 1, 1, 1],
      ],
      [
        [1],
        [1],
        [1],
        [1],
      ],
    ],
  ),
  Tetromino(
    startPosition: 1,
    frames: <List<List<int>>>[
      [
        [0, 1, 0],
        [1, 1, 1],
      ],
      [
        [1, 0],
        [1, 1],
        [1, 0],
      ],
      [
        [1, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 1],
        [1, 1],
        [0, 1],
      ],
    ],
  ),
  Tetromino(
    startPosition: 1,
    frames: <List<List<int>>>[
      [
        [1, 0, 0],
        [1, 1, 1],
      ],
      [
        [1, 1],
        [1, 0],
        [1, 0],
      ],
      [
        [1, 1, 1],
        [0, 0, 1],
      ],
      [
        [0, 1],
        [0, 1],
        [1, 1],
      ],
    ],
  ),
  Tetromino(
    startPosition: 1,
    frames: <List<List<int>>>[
      [
        [0, 0, 1],
        [1, 1, 1],
      ],
      [
        [1, 0],
        [1, 0],
        [1, 1],
      ],
      [
        [1, 1, 1],
        [1, 0, 0],
      ],
      [
        [1, 1],
        [0, 1],
        [0, 1],
      ],
    ],
  ),
];

/// Color bytes from `Block.BlockColor`, independent of the shape.
const List<int> blockColorBytes = <int>[2, 3, 4, 5, 6];

/// A live piece. Coordinates use the Android `Point`: x is the column, y the row.
class Piece {
  const Piece({
    required this.shapeIndex,
    required this.frameNumber,
    required this.colorByte,
    required this.x,
    required this.y,
  });

  final int shapeIndex;
  final int frameNumber;
  final int colorByte;
  final int x;
  final int y;

  Tetromino get tetromino => tetrominoes[shapeIndex];

  int get frameCount => tetromino.frameCount;

  List<List<int>> get cells => tetromino.frames[frameNumber];

  List<List<int>> cellsForFrame(int frame) => tetromino.frames[frame];

  Piece copyWith({int? frameNumber, int? x, int? y}) {
    return Piece(
      shapeIndex: shapeIndex,
      frameNumber: frameNumber ?? this.frameNumber,
      colorByte: colorByte,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

/// Spawns a piece the way `Block.createBlock` does.
Piece createPiece(int Function(int max) nextInt) {
  final shapeIndex = nextInt(tetrominoes.length);
  final colorByte = blockColorBytes[nextInt(blockColorBytes.length)];
  final startX = Board.columnCount ~/ 2 - tetrominoes[shapeIndex].startPosition;
  return Piece(
    shapeIndex: shapeIndex,
    frameNumber: 0,
    colorByte: colorByte,
    x: startX,
    y: 0,
  );
}
