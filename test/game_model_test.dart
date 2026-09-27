import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_game/game/board.dart';
import 'package:tetris_game/game/game_model.dart';
import 'package:tetris_game/game/motions.dart';
import 'package:tetris_game/game/pieces.dart';

void main() {
  GameModel started({int highScore = 0, void Function(int)? onHighScore}) {
    return GameModel(
      nextInt: (max) => 0,
      highScore: highScore,
      onHighScore: onHighScore,
    )..startGame();
  }

  Piece place(GameModel model, PieceType type, {int rotation = 0}) {
    final piece = Piece.spawn(
      type,
      columns: Board.columnCount,
    ).copyWith(rotation: rotation);
    model.current = piece;
    return piece;
  }

  void fillRow(Board board, int row, {Set<int> gaps = const {}}) {
    for (var col = 0; col < Board.columnCount; col++) {
      board.cells[row][col] = gaps.contains(col) ? Cell.empty : 9;
    }
  }

  test('well is 20×10 and starts awaiting', () {
    final model = GameModel();
    expect(model.board.cells, hasLength(20));
    expect(model.board.cells.first, hasLength(10));
    expect(model.status, GameStatus.awaitingStart);
  });

  test('7-bag deals every piece once per seven', () {
    var seed = 0;
    final bag = PieceBag((max) => (seed++ * 7 + 3) % max);
    for (var round = 0; round < 5; round++) {
      final dealt = {for (var i = 0; i < 7; i++) bag.next()};
      expect(dealt, PieceType.values.toSet());
    }
  });

  test('pieces spawn centered in the top rows', () {
    final model = started();
    for (final type in PieceType.values) {
      final piece = place(model, type);
      final cells = piece.cells.toList();
      expect(cells.map((c) => c.row).reduce((a, b) => a < b ? a : b), 0);
      final cols = cells.map((c) => c.col);
      expect(cols.reduce((a, b) => a < b ? a : b), type == PieceType.o ? 4 : 3);
    }
  });

  test('left and right stop at the walls without locking', () {
    final model = started();
    place(model, PieceType.t);
    for (var i = 0; i < 10; i++) {
      model.move(-1);
    }
    expect(
      model.current!.cells.map((c) => c.col).reduce((a, b) => a < b ? a : b),
      0,
    );
    expect(model.move(-1), isFalse);
    for (var i = 0; i < 10; i++) {
      model.move(1);
    }
    expect(
      model.current!.cells.map((c) => c.col).reduce((a, b) => a > b ? a : b),
      9,
    );
    expect(model.move(1), isFalse);
    expect(model.isActive, isTrue);
    expect(model.lockEpoch, 0);
  });

  test('rotation cycles through four states and back', () {
    final model = started();
    place(model, PieceType.t);
    model.stepDown();
    for (var i = 1; i <= 4; i++) {
      expect(model.rotate(), isTrue);
      expect(model.current!.rotation, i % 4);
    }
    expect(model.rotate(clockwise: false), isTrue);
    expect(model.current!.rotation, 3);
  });

  test('SRS wall kick lets a vertical I rotate flat against the wall', () {
    final model = started();
    // Vertical I in the rightmost column.
    model.current = const Piece(type: PieceType.i, rotation: 1, x: 7, y: 5);
    expect(model.current!.cells.every((c) => c.col == 9), isTrue);
    expect(model.rotate(), isTrue);
    expect(model.current!.rotation, 2);
    final cols = model.current!.cells.map((c) => c.col).toList()..sort();
    expect(cols, [6, 7, 8, 9]);
  });

  test('soft drop scores 1 per row and hard drop 2 per row then locks', () {
    final model = started();
    place(model, PieceType.o);
    expect(model.softDrop(), isTrue);
    expect(model.score, 1);

    final result = model.hardDrop()!;
    expect(result.gameOver, isFalse);
    expect(model.score, 1 + 17 * 2);
    expect(model.board.cells[18][4], PieceType.o.colorByte);
    expect(model.board.cells[19][5], PieceType.o.colorByte);
    expect(model.lockEpoch, 1);
    expect(model.current, isNotNull);
  });

  test('clears score 100/300/500/800 × level', () {
    for (final (count, points) in [(1, 100), (2, 300), (3, 500), (4, 800)]) {
      final model = started();
      for (var r = 0; r < count; r++) {
        fillRow(model.board, 19 - r, gaps: {9});
      }
      model.current = const Piece(type: PieceType.i, rotation: 1, x: 7, y: 0);
      final scoreBefore = model.score;
      final result = model.hardDrop()!;
      expect(model.clearingRows, hasLength(count));
      model.finishClear();
      // The I falls from rows 0–3 to rows 16–19: 16 rows of hard drop.
      expect(result.linesCleared, count);
      expect(model.lines, count);
      expect(model.score - scoreBefore, points + 16 * 2);
    }
  });

  test('full rows collapse and the stack above drops', () {
    final model = started();
    fillRow(model.board, 19, gaps: {4, 5});
    fillRow(model.board, 18, gaps: {4, 5});
    model.board.cells[17][0] = 9;
    place(model, PieceType.o);
    final result = model.hardDrop()!;
    expect(result.linesCleared, 2);
    // Full rows wait on the board for the clear animation.
    expect(model.isClearing, isTrue);
    expect(model.clearingRows, [18, 19]);
    expect(model.current, isNull);
    expect(model.board.cells[19].every((c) => c != Cell.empty), isTrue);

    model.finishClear();
    expect(model.isClearing, isFalse);
    expect(model.current, isNotNull);
    expect(model.board.cells[19][0], 9);
    expect(model.board.cells[18].every((c) => c == Cell.empty), isTrue);
    expect(model.board.cells[17].every((c) => c == Cell.empty), isTrue);
  });

  test('level rises every 10 lines and gravity speeds up', () {
    final model = started();
    final slow = model.gravityInterval;
    expect(model.level, 1);
    expect(slow, const Duration(seconds: 1));
    model.lines = 10;
    expect(model.level, 2);
    expect(model.gravityInterval < slow, isTrue);
  });

  test('blocked spawn ends the game and keeps the score', () {
    final saved = <int>[];
    final model = started(onHighScore: saved.add);
    // The O lands on rows 1–2, so the next piece has no room to spawn.
    for (var row = 3; row < 20; row++) {
      fillRow(model.board, row, gaps: {row % 10 == 4 ? 0 : row % 10});
    }
    place(model, PieceType.o);
    final result = model.hardDrop()!;
    expect(result.gameOver, isTrue);
    expect(model.isGameOver, isTrue);
    expect(model.score, greaterThan(0));
    model.saveHighScore();
    expect(saved, [model.score]);
    expect(model.highScore, model.score);
  });

  test('restart after game over starts clean', () {
    final model = started(highScore: 50);
    model.score = 10;
    model.lines = 12;
    model.status = GameStatus.over;
    model.restartGame();
    expect(model.isActive, isTrue);
    expect(model.score, 0);
    expect(model.lines, 0);
    expect(model.highScore, 50);
    expect(model.current, isNotNull);
  });

  test('touch zones use a diagonal split', () {
    expect(resolveTouchDirection(0.1, 0.5), Motion.left);
    expect(resolveTouchDirection(0.5, 0.1), Motion.rotate);
    expect(resolveTouchDirection(0.5, 0.9), Motion.down);
    expect(resolveTouchDirection(0.9, 0.5), Motion.right);
  });
}
