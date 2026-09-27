import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/board.dart';
import '../game/game_model.dart';
import '../game/motions.dart';
import 'high_score_store.dart';

final highScoreStoreProvider = Provider<HighScoreStore>(
  (ref) => SharedPrefsHighScoreStore(),
);

/// Injected so tests can force a piece sequence.
final rngProvider = Provider<int Function(int max)>((ref) {
  final random = Random();
  return random.nextInt;
});

final gameProvider = NotifierProvider<GameNotifier, GameSnapshot>(
  GameNotifier.new,
);

/// Owns the model, gravity, lock delay, and high-score writes.
class GameNotifier extends Notifier<GameSnapshot> {
  /// Time a grounded piece may still be moved before it locks.
  static const Duration lockDelay = Duration(milliseconds: 500);

  /// Moves/rotations that may restart the lock delay per new lowest row.
  static const int maxLockResets = 15;

  /// Line-clear delay: full rows flash and break up before collapsing.
  static const Duration clearDelay = Duration(milliseconds: 420);

  late GameModel _model;
  Timer? _gravityTimer;
  Timer? _lockTimer;
  Timer? _clearTimer;
  int _lockResets = 0;
  int _lowestRow = -100;
  int _token = 0;

  @override
  GameSnapshot build() {
    _token++;
    final token = _token;
    _cancelTimers();
    final store = ref.read(highScoreStoreProvider);
    _model = GameModel(nextInt: ref.read(rngProvider), onHighScore: store.save);
    ref.onDispose(() {
      if (_token == token) {
        _cancelTimers();
      }
    });
    unawaited(_loadHighScore(store, token));
    return _model.snapshot();
  }

  @visibleForTesting
  Board get debugBoard => _model.board;

  @visibleForTesting
  GameModel get debugModel => _model;

  Future<void> _loadHighScore(HighScoreStore store, int token) async {
    final stored = await store.read();
    if (token != _token) {
      return;
    }
    if (stored > _model.highScore) {
      _model.highScore = stored;
      _publish();
    }
  }

  /// Fresh awaiting-start session used when the game screen opens.
  void openGame() {
    _cancelTimers();
    _model = GameModel(
      nextInt: ref.read(rngProvider),
      onHighScore: ref.read(highScoreStoreProvider).save,
      highScore: _model.highScore,
    );
    _publish();
  }

  void start() {
    if (_model.isPaused) {
      resume();
      return;
    }
    if (_model.isActive) {
      return;
    }
    _model.startGame();
    _beginPiece();
  }

  void restart() {
    _model.saveHighScore();
    _model.restartGame();
    _beginPiece();
  }

  /// Stops the clocks without publishing, for when the game screen goes away.
  void suspend() {
    _cancelTimers();
  }

  /// Pauses an active game. Safe to call at any time.
  void pause() {
    if (!_model.isActive) {
      _cancelTimers();
      return;
    }
    _model.pause();
    _cancelTimers();
    _publish();
  }

  void resume() {
    if (!_model.isPaused) {
      return;
    }
    _model.resume();
    if (_model.isClearing) {
      _armClear();
    } else {
      _armGravity();
      if (_model.isGrounded) {
        _armLock();
      }
    }
    _publish();
  }

  void togglePause() {
    if (_model.isPaused) {
      resume();
    } else {
      pause();
    }
  }

  void handlePlayfieldTap(double x, double y) {
    if (!_model.isActive) {
      start();
      return;
    }
    handleMotion(resolveTouchDirection(x, y));
  }

  void handleMotion(Motion motion) {
    if (!_model.isActive || _model.isClearing) {
      return;
    }
    switch (motion) {
      case Motion.left:
        _manipulate(_model.move(-1));
      case Motion.right:
        _manipulate(_model.move(1));
      case Motion.rotate:
        _manipulate(_model.rotate());
      case Motion.rotateCounter:
        _manipulate(_model.rotate(clockwise: false));
      case Motion.down:
        if (_model.softDrop()) {
          _afterFall();
          // Soft drop replaces the pending gravity step.
          _armGravity();
          _publish();
        } else if (_lockTimer == null) {
          _armLock();
        }
      case Motion.hardDrop:
        final result = _model.hardDrop();
        if (result != null) {
          _afterLock(result);
        }
    }
  }

  void _manipulate(bool moved) {
    if (!moved) {
      return;
    }
    if (_model.isGrounded) {
      if (_lockTimer == null || _lockResets < maxLockResets) {
        if (_lockTimer != null) {
          _lockResets++;
        }
        _armLock();
      }
    } else {
      _cancelLock();
    }
    _publish();
  }

  /// Bookkeeping after the piece moved down a row.
  void _afterFall() {
    final y = _model.current!.y;
    if (y > _lowestRow) {
      _lowestRow = y;
      _lockResets = 0;
    }
    if (_model.isGrounded) {
      _armLock();
    } else {
      _cancelLock();
    }
  }

  void _beginPiece() {
    _cancelLock();
    _lockResets = 0;
    _lowestRow = _model.current?.y ?? -100;
    if (_model.isActive) {
      _armGravity();
      if (_model.isGrounded) {
        _armLock();
      }
    } else {
      _cancelTimers();
    }
    _publish();
  }

  void _afterLock(LockResult result) {
    if (result.gameOver) {
      _model.saveHighScore();
      _cancelTimers();
      _publish();
      return;
    }
    if (_model.isClearing) {
      _cancelTimers();
      _armClear();
      _publish();
      return;
    }
    // Re-arms gravity, which also picks up a level change.
    _beginPiece();
  }

  void _armClear() {
    _clearTimer?.cancel();
    final token = _token;
    _clearTimer = Timer(clearDelay, () {
      _clearTimer = null;
      if (token != _token || !_model.isActive || !_model.isClearing) {
        return;
      }
      _afterLock(_model.finishClear());
    });
  }

  void _armGravity() {
    _gravityTimer?.cancel();
    final token = _token;
    _gravityTimer = Timer.periodic(
      _model.gravityInterval,
      (_) => _onGravity(token),
    );
  }

  void _onGravity(int token) {
    if (token != _token || !_model.isActive || _model.isClearing) {
      return;
    }
    if (_model.stepDown()) {
      _afterFall();
      _publish();
    } else if (_lockTimer == null) {
      _armLock();
    }
  }

  void _armLock() {
    _lockTimer?.cancel();
    final token = _token;
    _lockTimer = Timer(lockDelay, () => _onLock(token));
  }

  void _onLock(int token) {
    _lockTimer = null;
    if (token != _token || !_model.isActive) {
      return;
    }
    if (!_model.isGrounded) {
      return;
    }
    _afterLock(_model.lock());
  }

  void _cancelLock() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  void _cancelTimers() {
    _gravityTimer?.cancel();
    _gravityTimer = null;
    _clearTimer?.cancel();
    _clearTimer = null;
    _cancelLock();
  }

  void _publish() {
    state = _model.snapshot();
  }
}
