import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/motions.dart';
import '../../providers/game_provider.dart';
import '../theme/neon.dart';

/// On-screen pad: left, rotate, soft drop, hard drop, right.
class GameControls extends ConsumerWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void send(Motion motion) =>
        ref.read(gameProvider.notifier).handleMotion(motion);

    return SizedBox(
      height: 64,
      child: Row(
        children: <Widget>[
          _PadButton(
            key: const Key('control-left'),
            icon: Icons.arrow_back_rounded,
            label: 'LEFT',
            repeat: true,
            onPress: () => send(Motion.left),
          ),
          _PadButton(
            key: const Key('control-rotate'),
            icon: Icons.autorenew_rounded,
            label: 'ROTATE',
            onPress: () => send(Motion.rotate),
          ),
          _PadButton(
            key: const Key('control-down'),
            icon: Icons.arrow_downward_rounded,
            label: 'DOWN',
            repeat: true,
            onPress: () => send(Motion.down),
          ),
          _PadButton(
            key: const Key('control-drop'),
            icon: Icons.keyboard_double_arrow_down_rounded,
            label: 'DROP',
            accent: Neon.magenta,
            onPress: () => send(Motion.hardDrop),
          ),
          _PadButton(
            key: const Key('control-right'),
            icon: Icons.arrow_forward_rounded,
            label: 'RIGHT',
            repeat: true,
            onPress: () => send(Motion.right),
          ),
        ],
      ),
    );
  }
}

/// Fires on touch-down (no tap delay). With [repeat], holding it auto-repeats
/// after a short delay, like DAS/ARR in Tetris.
class _PadButton extends StatefulWidget {
  const _PadButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPress,
    this.repeat = false,
    this.accent = Neon.cyan,
  });

  static const Duration repeatDelay = Duration(milliseconds: 170);
  static const Duration repeatRate = Duration(milliseconds: 50);

  final IconData icon;
  final String label;
  final VoidCallback onPress;
  final bool repeat;
  final Color accent;

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  Timer? _delay;
  Timer? _repeat;
  int? _pointer;

  void _down(PointerDownEvent event) {
    if (_pointer != null) {
      return;
    }
    _pointer = event.pointer;
    setState(() {});
    HapticFeedback.selectionClick().ignore();
    widget.onPress();
    if (widget.repeat) {
      _delay = Timer(_PadButton.repeatDelay, () {
        _repeat = Timer.periodic(
          _PadButton.repeatRate,
          (_) => widget.onPress(),
        );
      });
    }
  }

  void _up(PointerEvent event) {
    if (event.pointer != _pointer) {
      return;
    }
    _stop();
    setState(() {});
  }

  void _stop() {
    _pointer = null;
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pointer != null;
    final accent = widget.accent;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(
          button: true,
          label: widget.label,
          onTap: widget.onPress,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerUp: _up,
            onPointerCancel: _up,
            child: AnimatedScale(
              scale: pressed ? 0.94 : 1,
              duration: const Duration(milliseconds: 80),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: pressed
                        ? <Color>[
                            accent.withValues(alpha: 0.32),
                            accent.withValues(alpha: 0.14),
                          ]
                        : const <Color>[Color(0xB3141038), Color(0xCC0A0620)],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: pressed ? 1 : 0.85),
                    width: pressed ? 2 : 1.6,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: pressed ? 0.6 : 0.3),
                      blurRadius: pressed ? 20 : 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      widget.icon,
                      size: 24,
                      color: accent,
                      shadows: <Shadow>[
                        Shadow(
                          color: accent.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        style: rajdhani(
                          12,
                          color: Neon.ink,
                          weight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
