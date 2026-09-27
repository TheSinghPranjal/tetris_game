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
            icon: Icons.west_rounded,
            label: 'LEFT',
            repeat: true,
            onPress: () => send(Motion.left),
          ),
          _PadButton(
            key: const Key('control-rotate'),
            icon: Icons.rotate_right_rounded,
            label: 'ROTATE',
            onPress: () => send(Motion.rotate),
          ),
          _PadButton(
            key: const Key('control-down'),
            icon: Icons.south_rounded,
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
            icon: Icons.east_rounded,
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
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Semantics(
          button: true,
          label: widget.label,
          onTap: widget.onPress,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerUp: _up,
            onPointerCancel: _up,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              decoration: BoxDecoration(
                color: pressed
                    ? accent.withValues(alpha: 0.22)
                    : const Color(0x8812081C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent.withValues(alpha: pressed ? 0.9 : 0.4),
                  width: pressed ? 1.6 : 1,
                ),
                boxShadow: pressed
                    ? <BoxShadow>[
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(widget.icon, size: 24, color: accent),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: rajdhani(11, color: Neon.muted, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
