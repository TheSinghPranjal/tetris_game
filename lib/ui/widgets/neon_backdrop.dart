import 'package:flutter/material.dart';

import '../painter/backdrop_painter.dart';
import '../theme/neon.dart';

class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.65),
          radius: 1.15,
          colors: <Color>[Color(0xFF2A1148), Color(0xFF120824), Neon.bg],
          stops: <double>[0, 0.42, 1],
        ),
      ),
      child: CustomPaint(painter: const BackdropPainter(), child: child),
    );
  }
}
