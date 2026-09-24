import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/board.dart';
import '../game/game_model.dart';
import '../game/motions.dart';
import '../game/tick.dart';
import 'high_score_store.dart';

final highScoreStoreProvider = Provider<HighScoreStore>(
  (ref) => SharedPrefsHighScoreStore(),
);

/// Injected so tests can force a shape and color sequence.
final rngProvider = Provider<int Function(int max)>((ref) {
  final random = Random();
  return random.nextInt;
});

final gameProvider = NotifierProvider<GameNotifier, GameSnapshot>(
  GameNotifier.new,
);

/// Owns the model, the 500ms soft-drop loop, and high-score writes.
class GameNotifier extends Notifier<GameSnapshot> {
  late GameModel _model;
  final MoveScheduler _scheduler = MoveScheduler();
  Timer? _dropTimer;
  int _token = 0;

  @override
  GameSnapshot build() {
    _token++;
    _dropTimer?.cancel();
    final token = _token;
    final store = ref.read(highScoreStoreProvider);
    _model = GameModel(nextInt: ref.read(rngProvider), onHighScore: store.save);
    ref.onDispose(() {
      if (_token == token) {
        _dropTimer?.cancel();
        _dropTimer = null;
      }
    });
    unawaited(_loadHighScore(store, token));
    return _model.snapshot();
  }

  @visibleForTesting
  Board get debugBoard => _model.board;

  Future<void> _loadHighScore(HighScoreStore store, int token) async {
    final stored = await store.read();
    if (token != _token) {
      return;
    }
    if (stored > _model.highScore) {
      _model.highScore = stored;
      state = _model.snapshot();
    }
  }

  /// Fresh awaiting-start session used when the game screen opens.
  void openGame() {
    _cancelDrop();
    final best = _model.highScore;
    _model = GameModel(
      nextInt: ref.read(rngProvider),
      onHighScore: ref.read(highScoreStoreProvider).save,
      highScore: best,
    );
    _scheduler.reset();
    state = _model.snapshot();
  }

  void pause() {
    _cancelDrop();
  }

  void handlePlayfieldTap(double x, double y) {
    if (_model.isAwaitingStart || _model.isGameOver) {
      _model.startGame();
      _scheduler.reset();
      _commit(Motion.down, reschedule: true);
      return;
    }
    if (_model.isActive) {
      handleMotion(resolveTouchDirection(x, y));
    }
  }

  void handleMotion(Motion motion) {
    if (!_model.isActive) {
      return;
    }
    if (motion == Motion.down) {
      // Immediate soft drop. The pending gravity tick is left alone,
      // matching `TetrisView.setGameCommand` for DOWN. A lock that ends
      // the game still arms the follow-up tick inside [_commit].
      _commit(Motion.down, reschedule: false);
      return;
    }
    _commit(motion, reschedule: true);
  }

  void restart() {
    _model.restartGame();
    _scheduler.reset();
    _commit(Motion.down, reschedule: true);
  }

  void _commit(Motion motion, {required bool reschedule}) {
    final result = _model.generateField(motion);
    if (reschedule) {
      _scheduler.mark();
    }
    state = _model.snapshot(step: result);
    if (reschedule || _model.isGameOver) {
      _armDrop();
    }
  }

  void _armDrop() {
    _cancelDrop();
    final token = _token;
    _dropTimer = Timer(_scheduler.delay, () => _onTick(token));
  }

  void _onTick(int token) {
    _dropTimer = null;
    if (token != _token) {
      return;
    }
    if (_model.isGameOver) {
      _model.endGame();
      state = _model.snapshot();
      return;
    }
    if (_model.isActive) {
      _commit(Motion.down, reschedule: true);
    }
  }

  void _cancelDrop() {
    _dropTimer?.cancel();
    _dropTimer = null;
  }
}
