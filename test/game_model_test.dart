import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_game/game/board.dart';
import 'package:tetris_game/game/game_model.dart';
import 'package:tetris_game/game/motions.dart';
import 'package:tetris_game/game/pieces.dart';

void main() {
  GameModel scripted(
    List<int> rolls, {
    int highScore = 0,
    void Function(int score)? onHighScore,
  }) {
    var index = 0;
    return GameModel(
      highScore: highScore,
      onHighScore: onHighScore,
      nextInt: (max) {
        final value = rolls[index % rolls.length];
        index++;
        return value % max;
      },
    );
  }

  test('field is 20 rows by 10 columns and starts awaiting', () {
    final model = scripted(const [0]);
    expect(model.board.cells, hasLength(Board.rowCount));
    expect(model.board.cells.first, hasLength(Board.columnCount));
    expect(Board.rowCount, 20);
    expect(Board.columnCount, 10);
    expect(model.status, GameStatus.awaitingStart);
    expect(model.score, 0);
  });

  test('pieces spawn with the Android horizontal offset', () {
    for (var shape = 0; shape < tetrominoes.length; shape++) {
      final model = scripted(<int>[shape, 0, 0, 0]);
      model.startGame();
      expect(model.current!.shapeIndex, shape);
      expect(model.current!.y, 0);
      expect(model.current!.frameNumber, 0);
      expect(
        model.current!.x,
        Board.columnCount ~/ 2 - tetrominoes[shape].startPosition,
      );
      expect(blockColorBytes, contains(model.current!.colorByte));
    }
  });

  test('left, right, down, and rotate follow valid cells', () {
    final model = scripted(const [3, 0, 0, 0]);
    model.startGame();
    expect(model.current!.x, 3);

    model.generateField(Motion.left);
    expect(model.current!.x, 2);
    expect(model.score, 0);

    model.generateField(Motion.right);
    expect(model.current!.x, 3);

    model.generateField(Motion.down);
    expect(model.current!.y, 1);

    model.generateField(Motion.rotate);
    expect(model.current!.frameNumber, 1);
    expect(model.current!.cells, <List<int>>[
      [1],
      [1],
      [1],
      [1],
    ]);
  });

  test('a blocked sideways move or rotation does not lock or score', () {
    final model = scripted(const [3, 0, 0, 0]);
    model.startGame();
    model.current = model.current!.copyWith(x: 0);
    model.generateField(Motion.left);
    expect(model.current!.x, 0);
    expect(model.score, 0);
    expect(model.isActive, isTrue);

    model.current = model.current!.copyWith(x: 6, y: 18, frameNumber: 0);
    model.generateField(Motion.rotate);
    expect(model.current!.frameNumber, 0);
    expect(model.current!.y, 18);
    expect(model.score, 0);
  });

  test('locking a piece adds 10 and updates a beaten high score', () {
    final saved = <int>[];
    final model = scripted(const [0], onHighScore: saved.add);
    model.startGame();
    model.generateField(Motion.down);
    model.board.cells[3][4] = 2;
    model.board.cells[3][5] = 2;

    final step = model.generateField(Motion.down);
    expect(step.locked, isTrue);
    expect(step.gameOver, isTrue);
    expect(model.score, 10);
    expect(model.highScore, 10);
    expect(model.achievedScore, 10);
    expect(saved, <int>[10]);
    expect(
      model.board.cells.every((row) => row.every((cell) => cell == Cell.empty)),
      isTrue,
    );
  });

  test('high score is kept when the new score does not exceed it', () {
    final saved = <int>[];
    final model = scripted(const [0], highScore: 40, onHighScore: saved.add);
    model.startGame();
    model.generateField(Motion.down);
    model.board.cells[3][4] = 2;
    model.board.cells[3][5] = 2;
    model.generateField(Motion.down);
    expect(model.score, 10);
    expect(model.highScore, 40);
    expect(saved, isEmpty);
  });

  test('full rows shift down and a clear spawn does not end the game', () {
    final model = scripted(const [0]);
    model.startGame();
    for (var column = 0; column < Board.columnCount; column++) {
      if (column == 4 || column == 5) {
        continue;
      }
      model.board.cells[18][column] = 4;
      model.board.cells[19][column] = 5;
    }
    model.board.cells[10][0] = 3;

    StepResult? locked;
    for (var i = 0; i < 30 && locked == null; i++) {
      final step = model.generateField(Motion.down);
      if (step.locked) {
        locked = step;
      }
    }

    expect(locked, isNotNull);
    expect(locked!.linesCleared, 2);
    expect(locked.gameOver, isFalse);
    expect(model.score, 10);
    expect(model.isActive, isTrue);
    expect(model.board.cells[12][0], 3);
    expect(model.board.cells[10][0], Cell.empty);
    expect(model.board.cells[18].every((cell) => cell == Cell.empty), isTrue);
    expect(model.board.cells[19].every((cell) => cell == Cell.empty), isTrue);
  });

  test('a full row below a lock shifts the stack down one', () {
    final model = scripted(const [0]);
    model.startGame();
    model.generateField(Motion.down);
    model.board.cells[4][4] = 2;
    model.board.cells[4][5] = 2;
    for (var column = 0; column < Board.columnCount; column++) {
      model.board.cells[19][column] = 3;
    }
    model.board.cells[10][0] = 6;

    final step = model.generateField(Motion.down);
    expect(step.locked, isFalse);

    final locked = model.generateField(Motion.down);
    expect(locked.locked, isTrue);
    expect(locked.linesCleared, 1);
    expect(locked.gameOver, isFalse);
    expect(model.board.cells[19][0], Cell.empty);
    expect(model.board.cells[11][0], 6);
    expect(model.board.cells[5][4], 2);
  });

  test('endGame clears the score and restart starts a fresh active game', () {
    final model = scripted(const [0], highScore: 10);
    model.startGame();
    model.score = 30;
    model.achievedScore = 30;
    model.status = GameStatus.over;
    model.endGame();
    expect(model.score, 0);
    expect(model.achievedScore, 30);
    expect(model.highScore, 10);
    expect(model.isGameOver, isTrue);

    model.restartGame();
    expect(model.score, 0);
    expect(model.achievedScore, 0);
    expect(model.isActive, isTrue);
    expect(model.current, isNotNull);
    expect(model.highScore, 10);
  });
}
