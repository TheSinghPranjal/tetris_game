import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../game/board.dart';
import '../theme/neon.dart';

/// Crisp well, grid, and glowing cells for the 20×10 field.
class BoardPainter extends CustomPainter {
  const BoardPainter({
    required this.field,
    required this.fallingColor,
    required this.lineFlash,
  });

  final List<List<int>> field;
  final int? fallingColor;
  final bool lineFlash;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = field.length;
    final cols = rows == 0 ? Board.columnCount : field.first.length;
    final cell = size.width / cols;
    final board = Rect.fromLTWH(0, 0, size.width, cell * rows);
    final well = RRect.fromRectAndRadius(board, const Radius.circular(16));

    canvas.drawRRect(well, Paint()..color = Neon.well);

    final grid = Paint()
      ..color = const Color(0x18F6F2FF)
      ..strokeWidth = 1;
    for (var column = 1; column < cols; column++) {
      final x = column * cell;
      canvas.drawLine(Offset(x, 0), Offset(x, board.height), grid);
    }
    for (var row = 1; row < rows; row++) {
      final y = row * cell;
      canvas.drawLine(Offset(0, y), Offset(board.width, y), grid);
    }

    const inset = 1.5;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < cols; column++) {
        final value = field[row][column];
        if (value == Cell.empty) {
          continue;
        }
        final color = value == Cell.ephemeral
            ? Neon.block(fallingColor ?? 6)
            : Neon.block(value);
        final rect = Rect.fromLTWH(
          column * cell + inset,
          row * cell + inset,
          cell - inset * 2,
          cell - inset * 2,
        );
        _paintCell(canvas, rect, color);
      }
    }

    if (lineFlash) {
      canvas.drawRRect(well, Paint()..color = const Color(0x33FFFFFF));
    }

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = ui.Gradient.linear(board.topLeft, board.bottomRight, const [
        Neon.cyan,
        Neon.magenta,
      ]);
    canvas.drawRRect(well, border);
  }

  void _paintCell(Canvas canvas, Rect rect, Color color) {
    final radius = Radius.circular(rect.shortestSide * 0.18);
    final body = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(
      body.inflate(1.2),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [
            Color.lerp(color, Colors.white, 0.28)!,
            color,
            Color.lerp(color, Colors.black, 0.28)!,
          ],
          const [0, 0.45, 1],
        ),
    );
    final highlight = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left + rect.width * 0.12,
        rect.top + rect.height * 0.1,
        rect.width * 0.76,
        rect.height * 0.22,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(highlight, Paint()..color = const Color(0x66FFFFFF));
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.field != field ||
        oldDelegate.fallingColor != fallingColor ||
        oldDelegate.lineFlash != lineFlash;
  }
}

/// Small 4×4 preview of the upcoming piece.
class PreviewPainter extends CustomPainter {
  const PreviewPainter({required this.cells, required this.colorByte});

  final List<List<int>>? cells;
  final int? colorByte;

  @override
  void paint(Canvas canvas, Size size) {
    const grid = 4;
    final cell = size.shortestSide / grid;
    final shape = cells;
    if (shape == null || colorByte == null) {
      return;
    }
    final height = shape.length;
    final width = shape.first.length;
    final ox = ((grid - width) * cell) / 2;
    final oy = ((grid - height) * cell) / 2;
    const inset = 1.2;
    final color = Neon.block(colorByte!);
    for (var row = 0; row < height; row++) {
      for (var column = 0; column < width; column++) {
        if (shape[row][column] == Cell.empty) {
          continue;
        }
        final rect = Rect.fromLTWH(
          ox + column * cell + inset,
          oy + row * cell + inset,
          cell - inset * 2,
          cell - inset * 2,
        );
        final body = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas.drawRRect(body, Paint()..color = color);
        canvas.drawRRect(
          body,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: 0.35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PreviewPainter oldDelegate) {
    return oldDelegate.cells != cells || oldDelegate.colorByte != colorByte;
  }
}
