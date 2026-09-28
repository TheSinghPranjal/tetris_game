import 'package:flutter/material.dart';

import '../theme/neon.dart';

/// Full-bleed arcade scene (starfield, floating tetrominoes, neon floor)
/// behind both screens.
class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({super.key, required this.child});

  static const String asset = 'assets/images/game_background.jpg';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: Neon.bg),
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => const SizedBox(),
        ),
        // Darken the top a touch so the HUD reads over the starfield.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x8807010F),
                Color(0x0007010F),
                Color(0x0007010F),
                Color(0x6607010F),
              ],
              stops: <double>[0, 0.22, 0.75, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
