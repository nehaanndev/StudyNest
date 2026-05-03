import 'package:flutter/material.dart';

class StudyVisualTheme {
  const StudyVisualTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.muted,
  });

  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color muted;

  // Builds the Material theme that matches this StudyNest visual theme.
  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        onSurface: text,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Arial',
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }
}

const studyThemes = [
  StudyVisualTheme(
    id: 'cozyCafe',
    name: 'Cozy Cafe',
    description: 'Warm wood, latte foam, and soft lamps.',
    emoji: '☕',
    background: Color(0xFF19130F),
    surface: Color(0xFF2A1D17),
    surfaceAlt: Color(0xFF3A2820),
    primary: Color(0xFFB77B4E),
    secondary: Color(0xFF6F8A63),
    accent: Color(0xFFFFC56E),
    text: Color(0xFFFFF4E7),
    muted: Color(0xFFCDB8A3),
  ),
  StudyVisualTheme(
    id: 'rainyLibrary',
    name: 'Rainy Library',
    description: 'Book stacks, green lamps, and quiet rain.',
    emoji: '📚',
    background: Color(0xFF111818),
    surface: Color(0xFF1D2A28),
    surfaceAlt: Color(0xFF263934),
    primary: Color(0xFF7A9C7B),
    secondary: Color(0xFFC09B67),
    accent: Color(0xFFE8C76E),
    text: Color(0xFFF1F2DF),
    muted: Color(0xFFAAB7A7),
  ),
  StudyVisualTheme(
    id: 'midnightCity',
    name: 'Midnight City',
    description: 'Night skyline focus with soft neon glow.',
    emoji: '🌃',
    background: Color(0xFF09131D),
    surface: Color(0xFF111F2E),
    surfaceAlt: Color(0xFF1B2E41),
    primary: Color(0xFF6D95B8),
    secondary: Color(0xFFB78A68),
    accent: Color(0xFFFFD37A),
    text: Color(0xFFEAF4FF),
    muted: Color(0xFFA9B6C4),
  ),
  StudyVisualTheme(
    id: 'gardenMatcha',
    name: 'Garden Matcha',
    description: 'Soft plants, matcha, and morning study.',
    emoji: '🍵',
    background: Color(0xFF101811),
    surface: Color(0xFF1C2A1F),
    surfaceAlt: Color(0xFF293B2D),
    primary: Color(0xFF8FAF70),
    secondary: Color(0xFFD39B78),
    accent: Color(0xFFF2D36E),
    text: Color(0xFFF1F6E9),
    muted: Color(0xFFB7C4AD),
  ),
];

// Finds a visual theme by id and falls back to the default cozy theme.
StudyVisualTheme themeById(String id) {
  return studyThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => studyThemes.first,
  );
}
