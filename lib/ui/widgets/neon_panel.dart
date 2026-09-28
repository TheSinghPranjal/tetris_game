import 'package:flutter/material.dart';

import '../theme/neon.dart';

/// Dark glass card with a glowing neon border, used for HUD stats, the pad
/// buttons, and the board messages.
class NeonPanel extends StatelessWidget {
  const NeonPanel({
    super.key,
    required this.child,
    this.color = Neon.cyan,
    this.radius = 16,
    this.glow = 0.35,
    this.fill = const Color(0xB30A0620),
    this.borderWidth = 1.4,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final double radius;

  /// Strength of the outer glow, 0–1.
  final double glow;
  final Color fill;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color.lerp(fill, color, 0.08)!, fill],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.85),
          width: borderWidth,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: glow),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// "TETRIS" wordmark: violet → cyan → pink gradient with a neon glow.
class NeonTitle extends StatelessWidget {
  const NeonTitle({super.key, this.size = 30});

  final double size;

  static const List<Color> colors = <Color>[
    Color(0xFFC77DFF),
    Color(0xFF9D7BFF),
    Color(0xFF7FE9FF),
    Color(0xFFFF6BD6),
    Color(0xFFFF3DA8),
  ];

  @override
  Widget build(BuildContext context) {
    final style = orbitron(
      size,
      weight: FontWeight.w900,
      letterSpacing: size * 0.08,
    );
    return Stack(
      children: <Widget>[
        // Glow layer.
        Text(
          'TETRIS',
          style: style.copyWith(
            color: Colors.transparent,
            shadows: const <Shadow>[
              Shadow(color: Color(0xCCB14DFF), blurRadius: 18),
              Shadow(color: Color(0x88FF3DA8), blurRadius: 30),
            ],
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              const LinearGradient(colors: colors).createShader(bounds),
          child: Text('TETRIS', style: style),
        ),
      ],
    );
  }
}

/// Small glowing glass tetromino used as a title ornament.
class MiniTetromino extends StatelessWidget {
  const MiniTetromino({
    super.key,
    required this.cells,
    required this.color,
    this.cell = 11,
    this.angle = 0,
  });

  /// Occupied (row, col) cells.
  final List<(int, int)> cells;
  final Color color;
  final double cell;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final rows = cells.map((c) => c.$1).reduce((a, b) => a > b ? a : b) + 1;
    final cols = cells.map((c) => c.$2).reduce((a, b) => a > b ? a : b) + 1;
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: cols * cell,
        height: rows * cell,
        child: Stack(
          children: <Widget>[
            for (final (row, col) in cells)
              Positioned(
                left: col * cell,
                top: row * cell,
                width: cell,
                height: cell,
                child: Padding(
                  padding: const EdgeInsets.all(0.8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cell * 0.18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Color.lerp(color, Colors.white, 0.35)!,
                          color.withValues(alpha: 0.75),
                        ],
                      ),
                      border: Border.all(
                        color: Color.lerp(color, Colors.white, 0.5)!,
                        width: 0.8,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
