import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_model.dart';
import '../../game/motions.dart';
import '../../providers/game_provider.dart';
import '../painter/board_painter.dart';
import '../theme/neon.dart';
import '../widgets/control_legend.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/playfield.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameNotifier? _game;

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
        if (next.linesCleared > 0) {
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: <Widget>[
                  _TopBar(
                    onRestart: () => ref.read(gameProvider.notifier).restart(),
                  ),
                  const SizedBox(height: 10),
                  _Hud(state: state),
                  const SizedBox(height: 12),
                  const Expanded(child: Playfield()),
                  const SizedBox(height: 12),
                  const ControlLegend(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.read(gameProvider);
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      notifier.restart();
      return KeyEventResult.handled;
    }
    if (state.status != GameStatus.active) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        notifier.handlePlayfieldTap(0.5, 0.2);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final motion = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => Motion.left,
      LogicalKeyboardKey.arrowRight => Motion.right,
      LogicalKeyboardKey.arrowDown => Motion.down,
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.space => Motion.rotate,
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
    _game?.pause();
    super.dispose();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _RoundIcon(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'TETRIS',
            style: orbitron(16, letterSpacing: 3, shadows: titleGlow()),
          ),
        ),
        _RoundIcon(
          key: const Key('restart-button'),
          icon: Icons.refresh_rounded,
          tooltip: 'Restart',
          onPressed: onRestart,
        ),
      ],
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
      child: Material(
        color: const Color(0x6612081C),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Neon.cyan.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Neon.cyan, size: 20),
            ),
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
    return Row(
      children: <Widget>[
        Expanded(
          child: _Stat(label: 'SCORE', value: state.displayedScore),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Stat(label: 'BEST', value: state.highScore),
        ),
        const SizedBox(width: 8),
        _NextWell(state: state),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x9912081C),
        border: Border.all(color: Neon.violet.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: rajdhani(12, color: Neon.cyan, letterSpacing: 2),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$value',
                style: orbitron(22, color: Neon.ink, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextWell extends StatelessWidget {
  const _NextWell({required this.state});

  final GameSnapshot state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xCC090314),
        border: Border.all(color: Neon.cyan.withValues(alpha: 0.35)),
      ),
      child: SizedBox(
        width: 72,
        height: 64,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 4),
            Text(
              'NEXT',
              style: rajdhani(10, color: Neon.muted, letterSpacing: 1.4),
            ),
            Expanded(
              child: CustomPaint(
                painter: PreviewPainter(
                  cells: state.next?.cells,
                  colorByte: state.next?.colorByte,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
