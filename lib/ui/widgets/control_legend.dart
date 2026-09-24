import 'package:flutter/material.dart';

import '../theme/neon.dart';

/// The four playfield zones, in the same order a player meets them.
class ControlLegend extends StatelessWidget {
  const ControlLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _Chip(icon: Icons.west_rounded, label: 'LEFT'),
        _Chip(icon: Icons.rotate_right_rounded, label: 'ROTATE'),
        _Chip(icon: Icons.south_rounded, label: 'DROP'),
        _Chip(icon: Icons.east_rounded, label: 'RIGHT'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x6612081C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Neon.cyan.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: Neon.cyan),
            const SizedBox(width: 6),
            Text(
              label,
              style: rajdhani(13, color: Neon.muted, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
