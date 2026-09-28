import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../game/board.dart';
import '../../game/pieces.dart';
import '../theme/neon.dart';

/// Glossy glass block: soft glow, top-lit gradient, and a shine band.
void paintNeonCell(Canvas canvas, Rect rect, Color color) {
  final radius = Radius.circular(rect.shortestSide * 0.22);
  final body = RRect.fromRectAndRadius(rect, radius);
  final alpha = color.a;
  canvas.drawRRect(
    body.inflate(1.2),
    Paint()
      ..color = color.withValues(alpha: 0.5 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawRRect(
    body,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        [
          Color.lerp(color, Colors.white, 0.3)!,
          color,
          Color.lerp(color, Colors.black, 0.22)!,
        ],
        const [0, 0.5, 1],
      ),
  );
  // Gel shine across the top.
  final highlight = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      rect.left + rect.width * 0.14,
      rect.top + rect.height * 0.09,
      rect.width * 0.72,
      rect.height * 0.2,
    ),
    Radius.circular(rect.height * 0.1),
  );
  canvas.drawRRect(
    highlight,
    Paint()..color = Colors.white.withValues(alpha: 0.5 * alpha),
  );
  canvas.drawRRect(
    body.deflate(0.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color.lerp(
        color,
        Colors.white,
        0.45,
      )!.withValues(alpha: 0.7 * alpha),
  );
}

/// Crisp well, grid, and glowing cells for the 20×10 field.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.field,
    required this.ghost,
    required this.ghostColor,
    this.clearingRows = const <int>[],
    this.clear,
  }) : super(repaint: clear);

  /// Corner radius of the well, shared with the playfield frame.
  static const double radius = 20;

  final List<List<int>> field;
  final List<CellOffset> ghost;
  final int? ghostColor;

  /// Full rows being removed, animated by [clear] from 0 to 1.
  final List<int> clearingRows;
  final Animation<double>? clear;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = field.length;
    final cols = rows == 0 ? Board.columnCount : field.first.length;
    final cell = size.width / cols;
    final board = Rect.fromLTWH(0, 0, size.width, cell * rows);
    final well = RRect.fromRectAndRadius(board, const Radius.circular(radius));

    canvas.drawRRect(well, Paint()..color = const Color(0xE6060414));

    final grid = Paint()
      ..color = const Color(0x1A7FA8FF)
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
    if (ghostColor != null) {
      final ghostPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Neon.block(ghostColor!).withValues(alpha: 0.55);
      for (final spot in ghost) {
        if (spot.row < 0 || field[spot.row][spot.col] != Cell.empty) {
          continue;
        }
        final rect = Rect.fromLTWH(
          spot.col * cell + inset + 1,
          spot.row * cell + inset + 1,
          cell - inset * 2 - 2,
          cell - inset * 2 - 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          ghostPaint,
        );
      }
    }
    final t = clearingRows.isEmpty ? 0.0 : (clear?.value ?? 0.0);
    for (final row in clearingRows) {
      _paintClearBand(canvas, board.width, row, cell, t);
    }
    for (var row = 0; row < rows; row++) {
      final clearing = clearingRows.contains(row);
      for (var column = 0; column < cols; column++) {
        final value = field[row][column];
        if (value == Cell.empty) {
          continue;
        }
        if (clearing) {
          _paintClearingCell(canvas, row, column, cols, cell, value, t);
          continue;
        }
        final color = Neon.block(value);
        final rect = Rect.fromLTWH(
          column * cell + inset,
          row * cell + inset,
          cell - inset * 2,
          cell - inset * 2,
        );
        paintNeonCell(canvas, rect, color);
      }
    }

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = ui.Gradient.linear(board.topCenter, board.bottomCenter, const [
        Color(0xFF6FE7FF),
        Color(0xFF3D7BFF),
        Color(0xFF6FE7FF),
      ]);
    canvas.drawRRect(well.deflate(1), border);
  }

  /// Glowing band behind a clearing row: swells, then fades out.
  void _paintClearBand(
    Canvas canvas,
    double width,
    int row,
    double cell,
    double t,
  ) {
    final strength = math.sin(math.pi * t.clamp(0.0, 1.0));
    final band = Rect.fromLTWH(0, row * cell, width, cell);
    canvas.drawRect(
      band.inflate(cell * 0.35 * strength),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28 * strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.6),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: band.center,
        width: width * (1 - t * 0.6),
        height: 2,
      ),
      Paint()..color = Neon.cyan.withValues(alpha: 0.9 * strength),
    );
  }

  /// A block in a clearing row: flashes white, then shrinks and sparks,
  /// starting in the middle of the row and moving out to the walls.
  void _paintClearingCell(
    Canvas canvas,
    int row,
    int column,
    int cols,
    double cell,
    int value,
    double t,
  ) {
    const inset = 1.5;
    final flash = (t / 0.3).clamp(0.0, 1.0);
    final distance = ((column + 0.5) - cols / 2).abs() / (cols / 2);
    final start = 0.3 + 0.35 * distance;
    final gone = ((t - start) / 0.3).clamp(0.0, 1.0);
    if (gone >= 1) {
      return;
    }
    final center = Offset((column + 0.5) * cell, (row + 0.5) * cell);
    final side = (cell - inset * 2) * (1 - gone);
    final color = Color.lerp(Neon.block(value), Colors.white, flash * 0.85)!;
    paintNeonCell(
      canvas,
      Rect.fromCenter(center: center, width: side, height: side),
      color.withValues(alpha: 1 - gone * 0.6),
    );
    if (gone > 0) {
      final spark = Paint()
        ..color = Neon.block(value).withValues(alpha: 1 - gone)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      final reach = cell * 0.9 * gone;
      for (var i = 0; i < 4; i++) {
        final angle = (i * math.pi / 2) + column * 0.7 + row * 0.3;
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * reach,
          cell * 0.07 * (1 - gone) + 0.8,
          spark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.field != field ||
        oldDelegate.clearingRows != clearingRows ||
        oldDelegate.clear != clear ||
        oldDelegate.ghost != ghost ||
        oldDelegate.ghostColor != ghostColor;
  }
}

/// Centered preview of the upcoming piece.
class PreviewPainter extends CustomPainter {
  PreviewPainter({required PieceType? type})
    : cells = type == null ? null : previewMatrix(type),
      colorByte = type?.colorByte;

  final List<List<int>>? cells;
  final int? colorByte;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = cells;
    if (shape == null || colorByte == null) {
      return;
    }
    final height = shape.length;
    final width = shape.first.length;
    // Same cell size for every piece: room for a flat I or a two-row piece.
    final cell = math.min(size.width / 4, size.height / 2);
    final ox = (size.width - width * cell) / 2;
    final oy = (size.height - height * cell) / 2;
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
        paintNeonCell(canvas, rect, color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PreviewPainter oldDelegate) {
    return oldDelegate.cells != cells || oldDelegate.colorByte != colorByte;
  }
}
