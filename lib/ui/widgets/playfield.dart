import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_model.dart';
import '../../providers/game_provider.dart';
import '../painter/board_painter.dart';
import '../theme/neon.dart';

class Playfield extends ConsumerWidget {
  const Playfield({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          fallingColor: state.current?.colorByte,
                          lineFlash: state.linesCleared > 0,
                        ),
                      ),
                      if (state.linesCleared > 0)
                        Align(
                          alignment: const Alignment(0, -0.72),
                          child: _LineCallout(lines: state.linesCleared),
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
  const _LineCallout({required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final label = lines == 1 ? '1 LINE' : '$lines LINES';
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC07010F),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Neon.amber.withValues(alpha: 0.8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: orbitron(13, color: Neon.amber, letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}

class _BoardMessage extends StatelessWidget {
  const _BoardMessage({required this.state});

  final GameSnapshot state;

  @override
  Widget build(BuildContext context) {
    final over = state.status == GameStatus.over;
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
                  over ? 'GAME OVER' : 'TAP TO START',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
