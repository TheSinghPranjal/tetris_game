import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_model.dart';
import '../../game/motions.dart';
import '../../providers/game_provider.dart';
import '../painter/board_painter.dart';
import '../theme/neon.dart';
import '../widgets/game_controls.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/neon_panel.dart';
import '../widgets/playfield.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  GameNotifier? _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _game?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    _game = ref.read(gameProvider.notifier);
    ref.listen(gameProvider, (previous, next) {
      if (previous == null) {
        return;
      }
      if (next.status == GameStatus.over &&
          previous.status != GameStatus.over) {
        HapticFeedback.heavyImpact().ignore();
        return;
      }
      if (next.lockEpoch != previous.lockEpoch) {
        if (next.lastClear > 0) {
          HapticFeedback.heavyImpact().ignore();
        } else {
          HapticFeedback.mediumImpact().ignore();
        }
      }
    });

    final state = ref.watch(gameProvider);
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _onKey(event),
      child: Scaffold(
        body: NeonBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Column(
                children: <Widget>[
                  _TopBar(
                    paused: state.status == GameStatus.paused,
                    canPause:
                        state.status == GameStatus.active ||
                        state.status == GameStatus.paused,
                    onPause: () =>
                        ref.read(gameProvider.notifier).togglePause(),
                    onRestart: () => ref.read(gameProvider.notifier).restart(),
                  ),
                  const SizedBox(height: 8),
                  _Hud(state: state),
                  const SizedBox(height: 14),
                  const Expanded(child: Playfield()),
                  const SizedBox(height: 14),
                  const GameControls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final repeat = event is KeyRepeatEvent;
    final key = event.logicalKey;
    final notifier = ref.read(gameProvider.notifier);
    final status = ref.read(gameProvider).status;
    if (repeat &&
        key != LogicalKeyboardKey.arrowLeft &&
        key != LogicalKeyboardKey.arrowRight &&
        key != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      notifier.restart();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.escape) {
      notifier.togglePause();
      return KeyEventResult.handled;
    }
    if (status != GameStatus.active) {
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
        notifier.start();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final motion = switch (key) {
      LogicalKeyboardKey.arrowLeft => Motion.left,
      LogicalKeyboardKey.arrowRight => Motion.right,
      LogicalKeyboardKey.arrowDown => Motion.down,
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyX => Motion.rotate,
      LogicalKeyboardKey.keyZ ||
      LogicalKeyboardKey.controlLeft => Motion.rotateCounter,
      LogicalKeyboardKey.space => Motion.hardDrop,
      _ => null,
    };
    if (motion == null) {
      return KeyEventResult.ignored;
    }
    notifier.handleMotion(motion);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game?.suspend();
    super.dispose();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.paused,
    required this.canPause,
    required this.onPause,
    required this.onRestart,
  });

  final bool paused;
  final bool canPause;
  final VoidCallback onPause;
  final VoidCallback onRestart;

  static const double _button = 46;

  @override
  Widget build(BuildContext context) {
    // Both sides reserve the same width so the title stays centered.
    const side = _button * 2 + 8;
    return SizedBox(
      height: 58,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: side,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RoundIcon(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          const Expanded(child: FittedBox(child: _TitleLockup())),
          SizedBox(
            width: side,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (canPause) ...<Widget>[
                  _RoundIcon(
                    key: const Key('pause-button'),
                    icon: paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    tooltip: paused ? 'Resume' : 'Pause',
                    onPressed: onPause,
                  ),
                  const SizedBox(width: 8),
                ],
                _RoundIcon(
                  key: const Key('restart-button'),
                  icon: Icons.refresh_rounded,
                  tooltip: 'Restart',
                  onPressed: onRestart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wordmark flanked by two floating glass pieces, as in the key art.
class _TitleLockup extends StatelessWidget {
  const _TitleLockup();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: MiniTetromino(
              cells: <(int, int)>[(0, 1), (1, 0), (1, 1), (2, 0)],
              color: Color(0xFFA24DFF),
              angle: 0.18,
            ),
          ),
          SizedBox(width: 8),
          NeonTitle(size: 30),
          SizedBox(width: 6),
          Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: MiniTetromino(
              cells: <(int, int)>[(0, 0), (1, 0), (1, 1), (2, 1)],
              color: Color(0xFF2EC8FF),
              angle: -0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: _TopBar._button,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xB30A0620),
              border: Border.all(
                color: Neon.cyan.withValues(alpha: 0.9),
                width: 1.6,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Neon.cyan.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(icon, color: Neon.cyan, size: 24),
          ),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.state});

  final GameSnapshot state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 13,
            child: _Stat(
              label: 'SCORE',
              value: state.displayedScore,
              color: Neon.cyan,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 14,
            child: _Stat(
              label: 'BEST',
              value: state.highScore,
              color: const Color(0xFFB45CFF),
              crown: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 9,
            child: _Stat(
              label: 'LVL',
              value: state.level,
              color: const Color(0xFF8B6CFF),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 10,
            child: _Stat(
              label: 'LINES',
              value: state.lines,
              color: const Color(0xFFD65CFF),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(flex: 10, child: _NextWell(state: state)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.crown = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    return NeonPanel(
      color: color,
      radius: 14,
      glow: 0.3,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (crown) ...<Widget>[
                  const CustomPaint(
                    size: Size(16, 12),
                    painter: _CrownPainter(),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: rajdhani(
                    13,
                    color: crown ? Neon.ink : Neon.cyan,
                    weight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: orbitron(
                24,
                color: Neon.ink,
                weight: FontWeight.w900,
                letterSpacing: 0.5,
                shadows: <Shadow>[
                  Shadow(color: color.withValues(alpha: 0.6), blurRadius: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold crown next to BEST.
class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.25)
      ..lineTo(w * 0.28, h * 0.6)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.72, h * 0.6)
      ..lineTo(w, h * 0.25)
      ..lineTo(w * 0.88, h)
      ..lineTo(w * 0.12, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Neon.amber.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = Neon.amber);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) => false;
}

class _NextWell extends StatelessWidget {
  const _NextWell({required this.state});

  final GameSnapshot state;

  @override
  Widget build(BuildContext context) {
    return NeonPanel(
      color: Neon.cyan,
      radius: 14,
      glow: 0.3,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      child: Column(
        children: <Widget>[
          Text(
            'NEXT',
            style: rajdhani(
              13,
              color: Neon.ink,
              weight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: PreviewPainter(type: state.next),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
