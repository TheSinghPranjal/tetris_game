import 'package:flutter/material.dart';

import '../theme/neon.dart';

/// Faint arcade grid with a vignette, painted behind both screens.
class BackdropPainter extends CustomPainter {
  const BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Neon.grid
      ..strokeWidth = 1;
    const gap = 32.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final vignette = Paint()
      ..shader = const RadialGradient(
        radius: 0.95,
        colors: <Color>[Color(0x0007010F), Color(0xE607010F)],
        stops: <double>[0.4, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant BackdropPainter oldDelegate) => false;
}
