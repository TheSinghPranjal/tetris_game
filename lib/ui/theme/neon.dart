import 'package:flutter/material.dart';

/// Dark arcade palette.
abstract final class Neon {
  static const Color bg = Color(0xFF07010F);
  static const Color bgRaised = Color(0xFF160A28);
  static const Color well = Color(0xFF090314);
  static const Color cyan = Color(0xFF3DFFF3);
  static const Color magenta = Color(0xFFFF2BD6);
  static const Color violet = Color(0xFF8B6CFF);
  static const Color amber = Color(0xFFFFC857);
  static const Color ink = Color(0xFFF6F2FF);
  static const Color muted = Color(0xFFC4B6E0);
  static const Color grid = Color(0x22F6F2FF);

  /// Guideline piece colors (I, O, T, S, Z, J, L), pushed toward neon.
  static const Map<int, Color> blocks = <int, Color>{
    2: Color(0xFF3DFFF3),
    3: Color(0xFFFFE14A),
    4: Color(0xFFB45CFF),
    5: Color(0xFF39FF7A),
    6: Color(0xFFFF3D6E),
    7: Color(0xFF4D7CFF),
    8: Color(0xFFFF9F1C),
  };

  static Color block(int byte) => blocks[byte] ?? cyan;
}

TextStyle orbitron(
  double size, {
  Color color = Neon.ink,
  FontWeight weight = FontWeight.w700,
  double letterSpacing = 1.5,
  List<Shadow>? shadows,
}) {
  return TextStyle(
    fontFamily: 'Orbitron',
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: 1.05,
    shadows: shadows,
  );
}

TextStyle rajdhani(
  double size, {
  Color color = Neon.ink,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0.6,
}) {
  return TextStyle(
    fontFamily: 'Rajdhani',
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: 1,
  );
}

ThemeData neonTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Neon.bg,
    splashFactory: NoSplash.splashFactory,
    colorScheme: const ColorScheme.dark(
      primary: Neon.cyan,
      secondary: Neon.magenta,
      surface: Neon.bgRaised,
    ),
  );
}

List<Shadow> titleGlow() {
  return const <Shadow>[
    Shadow(color: Color(0xCCFF2BD6), blurRadius: 18),
    Shadow(color: Color(0x993DFFF3), blurRadius: 28),
  ];
}
