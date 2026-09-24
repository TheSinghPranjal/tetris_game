import 'dart:math';

import 'board.dart';
import 'motions.dart';
import 'pieces.dart';

/// `AppModel.Statuses`.
enum GameStatus { awaitingStart, active, over }

/// What one call to [GameModel.generateField] changed.
class StepResult {
  const StepResult({
    this.locked = false,
    this.linesCleared = 0,
    this.gameOver = false,
    this.highScoreUpdated = false,
  });

  final bool locked;
  final int linesCleared;
  final bool gameOver;
  final bool highScoreUpdated;
}

/// Immutable view of the model for Riverpod and the painter.
class GameSnapshot {
  const GameSnapshot({
    required this.status,
    required this.score,
    required this.highScore,
    required this.achievedScore,
    required this.field,
    required this.current,
    required this.next,
    required this.linesCleared,
    required this.lockEpoch,
  });

  final GameStatus status;
  final int score;
  final int highScore;
  final int achievedScore;
  final List<List<int>> field;
  final Piece? current;
  final Piece? next;
  final int linesCleared;
  final int lockEpoch;

  /// Score shown in the HUD. Game over keeps the result that was reached.
  int get displayedScore => status == GameStatus.over ? achievedScore : score;
}

/// Port of `AppModel`: movement, rotation, lock, line clear, and game over.
class GameModel {
  GameModel({
    int Function(int max)? nextInt,
    this.onHighScore,
    this.highScore = 0,
  }) : _nextInt = nextInt ?? Random().nextInt;

  final int Function(int max) _nextInt;
  final void Function(int score)? onHighScore;

  final Board board = Board();

  GameStatus status = GameStatus.awaitingStart;
  int score = 0;
  int highScore;
  int achievedScore = 0;
  int lockEpoch = 0;
  Piece? current;
  Piece? next;

  bool get isActive => status == GameStatus.active;
  bool get isAwaitingStart => status == GameStatus.awaitingStart;
  bool get isGameOver => status == GameStatus.over;

  void startGame() {
    if (!isActive) {
      status = GameStatus.active;
      current = createPiece(_nextInt);
      next = createPiece(_nextInt);
    }
  }

  void restartGame() {
    _resetModel();
    startGame();
  }

  /// Called on the tick after spawn is blocked, matching `AppModel.endGame`.
  void endGame() {
    score = 0;
    status = GameStatus.over;
  }

  void _resetModel() {
    board.reset(ephemeralOnly: false);
    status = GameStatus.awaitingStart;
    score = 0;
    achievedScore = 0;
    lockEpoch = 0;
    current = null;
    next = null;
  }

  StepResult generateField(Motion action) {
    final piece = current;
    if (!isActive || piece == null) {
      return const StepResult();
    }

    board.reset();
    var frame = piece.frameNumber;
    var x = piece.x;
    var y = piece.y;

    switch (action) {
      case Motion.left:
        x -= 1;
      case Motion.right:
        x += 1;
      case Motion.down:
        y += 1;
      case Motion.rotate:
        frame += 1;
        if (frame >= piece.frameCount) {
          frame = 0;
        }
    }

    final shape = piece.cellsForFrame(frame);
    if (!board.validTranslation(x, y, shape)) {
      board.translate(piece.x, piece.y, piece.cells);
      if (action == Motion.down) {
        return _lockPiece(piece);
      }
      return const StepResult();
    }

    board.translate(x, y, shape);
    current = piece.copyWith(frameNumber: frame, x: x, y: y);
    return const StepResult();
  }

  StepResult _lockPiece(Piece piece) {
    final highScoreUpdated = _boostScore();
    board.persist(piece.colorByte);
    final linesCleared = board.assess();
    current = next ?? createPiece(_nextInt);
    next = createPiece(_nextInt);
    lockEpoch++;

    final spawned = current;
    if (spawned == null || !_canPlace(spawned)) {
      achievedScore = score;
      status = GameStatus.over;
      current = null;
      next = null;
      board.reset(ephemeralOnly: false);
      return StepResult(
        locked: true,
        linesCleared: linesCleared,
        gameOver: true,
        highScoreUpdated: highScoreUpdated,
      );
    }

    return StepResult(
      locked: true,
      linesCleared: linesCleared,
      highScoreUpdated: highScoreUpdated,
    );
  }

  bool _boostScore() {
    score += 10;
    if (score > highScore) {
      highScore = score;
      onHighScore?.call(score);
      return true;
    }
    return false;
  }

  bool _canPlace(Piece piece) {
    return board.validTranslation(piece.x, piece.y, piece.cells);
  }

  GameSnapshot snapshot({StepResult? step}) {
    return GameSnapshot(
      status: status,
      score: score,
      highScore: highScore,
      achievedScore: achievedScore,
      field: board.copyCells(),
      current: current,
      next: next,
      linesCleared: step?.linesCleared ?? 0,
      lockEpoch: lockEpoch,
    );
  }
}
