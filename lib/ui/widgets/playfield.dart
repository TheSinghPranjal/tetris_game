import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_model.dart';
import '../../providers/game_provider.dart';
import '../painter/board_painter.dart';
import '../theme/neon.dart';

class Playfield extends ConsumerStatefulWidget {
  const Playfield({super.key});

  @override
  ConsumerState<Playfield> createState() => _PlayfieldState();
}

class _PlayfieldState extends ConsumerState<Playfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clear = AnimationController(
    vsync: this,
    duration: GameNotifier.clearDelay,
  );

  @override
  void dispose() {
    _clear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameProvider, (previous, next) {
      if (next.clearingRows.isEmpty) {
        return;
      }
      final newLock = previous == null || previous.lockEpoch != next.lockEpoch;
      final resumed =
          previous?.status == GameStatus.paused &&
          next.status == GameStatus.active;
      if (newLock || resumed) {
        // A resume restarts the clear delay, so replay the whole effect.
        _clear.forward(from: 0);
      } else if (next.status == GameStatus.paused) {
        _clear.stop();
      }
    });
    final state = ref.watch(gameProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = width * BoardAspect.ratio;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height / BoardAspect.ratio;
        }
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Neon.cyan.withValues(alpha: 0.16),
                    blurRadius: 28,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Neon.magenta.withValues(alpha: 0.12),
                    blurRadius: 42,
                  ),
                ],
              ),
              child: GestureDetector(
                key: const Key('playfield'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (width == 0 || height == 0) {
                    return;
                  }
                  ref
                      .read(gameProvider.notifier)
                      .handlePlayfieldTap(
                        details.localPosition.dx / width,
                        details.localPosition.dy / height,
                      );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CustomPaint(
                        painter: BoardPainter(
                          field: state.field,
                          ghost: state.ghost,
                          ghostColor: state.current?.colorByte,
                          clearingRows: state.clearingRows,
                          clear: _clear,
                        ),
                      ),
                      if (state.lastClear > 0)
                        Align(
                          alignment: const Alignment(0, -0.72),
                          child: _LineCallout(
                            key: ValueKey<int>(state.lockEpoch),
                            lines: state.lastClear,
                          ),
                        ),
                      if (state.status != GameStatus.active)
                        _BoardMessage(state: state),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

abstract final class BoardAspect {
  static const double ratio = 2;
}

class _LineCallout extends StatelessWidget {
  const _LineCallout({super.key, required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final label = switch (lines) {
      1 => 'SINGLE',
      2 => 'DOUBLE',
      3 => 'TRIPLE',
      _ => 'TETRIS!',
    };
    return IgnorePointer(
      child:
          DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC07010F),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Neon.amber.withValues(alpha: 0.8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Text(
                    label,
                    style: orbitron(13, color: Neon.amber, letterSpacing: 2),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 120.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 160.ms)
              .then(delay: 700.ms)
              .fadeOut(duration: 300.ms),
    );
  }
}

class _BoardMessage extends StatelessWidget {
  const _BoardMessage({required this.state});

  final GameSnapshot state;

  @override
  Widget build(BuildContext context) {
    final over = state.status == GameStatus.over;
    final paused = state.status == GameStatus.paused;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xB307010F)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  over
                      ? 'GAME OVER'
                      : paused
                      ? 'PAUSED'
                      : 'TAP TO START',
                  textAlign: TextAlign.center,
                  style: orbitron(
                    over ? 26 : 22,
                    letterSpacing: 2.4,
                    shadows: titleGlow(),
                  ),
                ),
                if (over) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    '${state.displayedScore}',
                    style: orbitron(32, color: Neon.amber, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TAP TO PLAY',
                    style: rajdhani(16, color: Neon.cyan, letterSpacing: 2),
                  ),
                ],
                if (paused) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'TAP TO RESUME',
                    style: rajdhani(16, color: Neon.cyan, letterSpacing: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
