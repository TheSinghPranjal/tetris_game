/// Gravity cadence from `TetrisView` (`DELAY = 500`).
class MoveScheduler {
  MoveScheduler({
    this.delay = const Duration(milliseconds: 500),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration delay;
  final DateTime Function() _clock;
  DateTime _lastMove = DateTime.fromMillisecondsSinceEpoch(0);

  /// True once [delay] has elapsed since the last accepted sideways move or drop.
  ///
  /// The Android view uses a strict `>` comparison against a handler posted for
  /// exactly 500ms, which can skip a tick when the callback is on time. This
  /// scheduler treats the boundary as due so the soft drop keeps its cadence.
  bool get isDue => _clock().difference(_lastMove) >= delay;

  void mark() {
    _lastMove = _clock();
  }

  void reset() {
    _lastMove = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
