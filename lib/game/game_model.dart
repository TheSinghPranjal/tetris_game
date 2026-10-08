import 'dart:math';

import 'board.dart';
import 'pieces.dart';

enum GameStatus { awaitingStart, active, paused, over }

/// What one lock changed.
class LockResult {
  const LockResult({required this.linesCleared, required this.gameOver});

  final int linesCleared;
  final bool gameOver;
}

/// Immutable view of the model for Riverpod and the painter.
class GameSnapshot {
  const GameSnapshot({
    required this.status,
    required this.score,
    required this.highScore,
    required this.level,
    required this.lines,
    required this.field,
    required this.ghost,
    required this.current,
    required this.next,
    required this.lastClear,
    required this.clearingRows,
    required this.lockEpoch,
  });

  final GameStatus status;
  final int score;
  final int highScore;
  final int level;
  final int lines;

  /// Locked cells with the falling piece drawn in.
  final List<List<int>> field;

  /// Where the falling piece would land.
  final List<CellOffset> ghost;
  final Piece? current;
  final PieceType? next;

  /// Lines cleared by the most recent lock (0 if none).
  final int lastClear;

  /// Full rows still on the board while the line-clear animation plays.
  final List<int> clearingRows;

  /// Increments on every lock, so the UI can react once per lock.
  final int lockEpoch;

  int get displayedScore => score;
}

/// Guideline falling-block rules: SRS rotation with wall kicks, 7-bag, soft and
/// hard drop, level-based gravity, and standard line-clear scoring.
class GameModel {
  GameModel({
    int Function(int max)? nextInt,
    this.onHighScore,
    this.highScore = 0,
  }) : _bag = PieceBag(nextInt ?? Random().nextInt);

  static const int linesPerLevel = 10;
  static const List<int> clearPoints = <int>[0, 100, 300, 500, 800];

  final PieceBag _bag;
  final void Function(int score)? onHighScore;

  final Board board = Board();

  GameStatus status = GameStatus.awaitingStart;
  int score = 0;
  int highScore;
  int lines = 0;
  int lastClear = 0;
  int lockEpoch = 0;
  List<int> clearingRows = const <int>[];
  Piece? current;
  PieceType? next;

  bool get isActive => status == GameStatus.active;
  bool get isPaused => status == GameStatus.paused;
  bool get isAwaitingStart => status == GameStatus.awaitingStart;
  bool get isGameOver => status == GameStatus.over;

  /// True between a lock that filled rows and [finishClear].
  bool get isClearing => clearingRows.isNotEmpty;

  int get level => 1 + lines ~/ linesPerLevel;

  /// Guideline gravity: (0.8 − (level − 1) × 0.007)^(level − 1) seconds/row.
  Duration get gravityInterval {
    final l = min(level, 20) - 1;
    final seconds = pow(0.8 - l * 0.007, l).toDouble();
    return Duration(microseconds: max(16000, (seconds * 1e6).round()));
  }

  void startGame() {
    if (isActive || isPaused) {
      return;
    }
    if (isGameOver) {
      _reset();
    }
    status = GameStatus.active;
    next = _bag.next();
    _spawn();
  }

  void restartGame() {
    _reset();
    startGame();
  }

  void pause() {
    if (isActive) {
      status = GameStatus.paused;
    }
  }

  void resume() {
    if (isPaused) {
      status = GameStatus.active;
    }
  }

  void _reset() {
    board.clear();
    status = GameStatus.awaitingStart;
    score = 0;
    lines = 0;
    lastClear = 0;
    lockEpoch = 0;
    clearingRows = const <int>[];
    current = null;
    next = null;
  }

  bool _tryPlace(Piece candidate) {
    if (!board.fits(candidate)) {
      return false;
    }
    current = candidate;
    return true;
  }

  /// Shifts the piece sideways by [dx]. Returns true if it moved.
  bool move(int dx) {
    final piece = current;
    if (!isActive || piece == null) {
      return false;
    }
    return _tryPlace(piece.copyWith(x: piece.x + dx));
  }

  /// SRS rotation with wall kicks. Returns true if the piece turned.
  bool rotate({bool clockwise = true}) {
    final piece = current;
    if (!isActive || piece == null) {
      return false;
    }
    final to = (piece.rotation + (clockwise ? 1 : 3)) % 4;
    for (final kick in kicksFor(piece.type, piece.rotation, to)) {
      final candidate = piece.copyWith(
        rotation: to,
        x: piece.x + kick.dx,
        y: piece.y + kick.dy,
      );
      if (_tryPlace(candidate)) {
        return true;
      }
    }
    return false;
  }

  /// True when the piece is resting on the stack or the floor.
  bool get isGrounded {
    final piece = current;
    return piece != null && !board.fits(piece.copyWith(y: piece.y + 1));
  }

  /// Gravity step: one row down, no points. Returns true if it moved.
  bool stepDown() {
    final piece = current;
    if (!isActive || piece == null) {
      return false;
    }
    return _tryPlace(piece.copyWith(y: piece.y + 1));
  }

  /// Player soft drop: one row down for 1 point. Does not lock by itself.
  bool softDrop() {
    if (!stepDown()) {
      return false;
    }
    _addScore(1);
    return true;
  }

  /// Drops straight to the ghost position for 2 points a row, then locks.
  LockResult? hardDrop() {
    final piece = current;
    if (!isActive || piece == null) {
      return null;
    }
    var rows = 0;
    while (stepDown()) {
      rows++;
    }
    _addScore(rows * 2);
    return lock();
  }

  /// Locks the current piece and scores any full rows.
  ///
  /// Full rows stay on the board (see [clearingRows]) so the UI can animate
  /// them; call [finishClear] to collapse them and spawn the next piece.
  /// Without full rows the next piece spawns right away.
  LockResult lock() {
    final piece = current!;
    final visible = board.lock(piece);
    final full = board.fullRows();
    _addScore(clearPoints[full.length] * level);
    lines += full.length;
    lastClear = full.length;
    lockEpoch++;
    current = null;

    if (!visible) {
      status = GameStatus.over;
      return LockResult(linesCleared: full.length, gameOver: true);
    }
    if (full.isNotEmpty) {
      clearingRows = full;
      return LockResult(linesCleared: full.length, gameOver: false);
    }
    return finishClear();
  }

  /// Collapses the rows from the last lock and spawns the next piece.
  LockResult finishClear() {
    final cleared = clearingRows.length;
    board.removeRows(clearingRows);
    clearingRows = const <int>[];
    if (!_spawn()) {
      return LockResult(linesCleared: cleared, gameOver: true);
    }
    return LockResult(linesCleared: cleared, gameOver: false);
  }

  /// Brings in the next piece. Returns false on a block out.
  bool _spawn() {
    final piece = Piece.spawn(next!, columns: Board.columnCount);
    next = _bag.next();
    if (!board.fits(piece)) {
      status = GameStatus.over;
      return false;
    }
    current = piece;
    return true;
  }

  void _addScore(int points) {
    if (points <= 0) {
      return;
    }
    score += points;
    if (score > highScore) {
      highScore = score;
    }
  }

  /// Persists the high score if this game set it.
  void saveHighScore() {
    if (score > 0 && score >= highScore) {
      onHighScore?.call(highScore);
    }
  }

  List<CellOffset> ghostCells() {
    var piece = current;
    if (piece == null) {
      return const [];
    }
    while (board.fits(piece!.copyWith(y: piece.y + 1))) {
      piece = piece.copyWith(y: piece.y + 1);
    }
    return piece.cells.toList(growable: false);
  }

  GameSnapshot snapshot() {
    final field = board.copyCells();
    final piece = current;
    if (piece != null) {
      for (final cell in piece.cells) {
        if (cell.row >= 0) {
          field[cell.row][cell.col] = piece.colorByte;
        }
      }
    }
    return GameSnapshot(
      status: status,
      score: score,
      highScore: highScore,
      level: level,
      lines: lines,
      field: field,
      ghost: ghostCells(),
      current: piece,
      next: next,
      lastClear: lastClear,
      clearingRows: clearingRows,
      lockEpoch: lockEpoch,
    );
  }
}
