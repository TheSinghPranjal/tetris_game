import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_model.dart';
import '../../providers/game_provider.dart';
import '../painter/board_painter.dart';
import '../theme/neon.dart';
import 'neon_panel.dart';

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
                borderRadius: BorderRadius.circular(BoardPainter.radius),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x663D9BFF), blurRadius: 22),
                  BoxShadow(
                    color: Color(0x406FE7FF),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                  BoxShadow(color: Color(0x33B14DFF), blurRadius: 48),
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
                  borderRadius: BorderRadius.circular(BoardPainter.radius),
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
      _ => 'QUAD!',
    };
    return IgnorePointer(
      child:
          NeonPanel(
                color: Neon.amber,
                radius: 999,
                glow: 0.5,
                fill: const Color(0xD90B0826),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                child: Text(
                  label,
                  style: orbitron(
                    14,
                    color: Neon.amber,
                    weight: FontWeight.w900,
                    letterSpacing: 2,
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

/// Glass card over the well for start, pause, and game over.
class _BoardMessage extends StatelessWidget {
  const _BoardMessage({required this.state});

  final GameSnapshot state;

  @override
  Widget build(BuildContext context) {
    final (title, action) = switch (state.status) {
      GameStatus.over => ('GAME OVER', 'TAP TO PLAY'),
      GameStatus.paused => ('PAUSED', 'TAP TO RESUME'),
      _ => ('READY?', 'TAP TO START'),
    };
    return IgnorePointer(
      child: ColoredBox(
        color: const Color(0x4D07010F),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: NeonPanel(
              color: const Color(0xFF7A6CFF),
              radius: 22,
              glow: 0.4,
              fill: const Color(0xD90B0826),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: orbitron(
                        28,
                        weight: FontWeight.w900,
                        letterSpacing: 1.6,
                        shadows: const <Shadow>[
                          Shadow(color: Color(0x99B14DFF), blurRadius: 16),
                        ],
                      ),
                    ),
                  ),
                  if (state.status == GameStatus.over) ...<Widget>[
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${state.displayedScore}',
                        style: orbitron(
                          40,
                          color: Neon.amber,
                          weight: FontWeight.w900,
                          letterSpacing: 1,
                          shadows: <Shadow>[
                            Shadow(
                              color: Neon.amber.withValues(alpha: 0.6),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _ActionPill(label: action),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return NeonPanel(
      color: Neon.cyan,
      radius: 999,
      glow: 0.5,
      borderWidth: 1.8,
      fill: const Color(0xCC0A2A3A),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: rajdhani(
            17,
            color: Neon.cyan,
            weight: FontWeight.w700,
            letterSpacing: 2.4,
          ),
        ),
      ),
    );
  }
}
