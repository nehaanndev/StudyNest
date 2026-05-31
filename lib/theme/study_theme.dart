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

  // Reports whether this palette should use dark Material defaults.
  bool get isDark {
    return background.computeLuminance() < 0.45;
  }

  // Builds the Material theme that matches this StudyNest visual theme.
  ThemeData toThemeData() {
    final baseTheme = ThemeData.light();
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
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
      textTheme: baseTheme.textTheme.apply(bodyColor: text, displayColor: text),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.90),
        indicatorColor: accent.withValues(alpha: 0.28),
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? text : muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? accent : muted);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
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
    description: 'Warm lights, soft jazz, and rainy days.',
    emoji: '☕',
    background: Color(0xFFF3DEC1),
    surface: Color(0xFFFFF3DE),
    surfaceAlt: Color(0xFFEBC99D),
    primary: Color(0xFF5B2F12),
    secondary: Color(0xFF7A461F),
    accent: Color(0xFFD9963B),
    text: Color(0xFF321B0E),
    muted: Color(0xFF73563E),
  ),
  StudyVisualTheme(
    id: 'rainyLibrary',
    name: 'Rainy Library',
    description: 'Quiet pages, gentle rain, and endless knowledge.',
    emoji: '📚',
    background: Color(0xFFE1D0B6),
    surface: Color(0xFFFFF2DC),
    surfaceAlt: Color(0xFFD5C099),
    primary: Color(0xFF4D321F),
    secondary: Color(0xFF394733),
    accent: Color(0xFFC98E35),
    text: Color(0xFF2B1B12),
    muted: Color(0xFF6B5948),
  ),
  StudyVisualTheme(
    id: 'midnightCity',
    name: 'Midnight City',
    description: 'City lights, late nights, and laser focus.',
    emoji: '🌃',
    background: Color(0xFFD9D0BD),
    surface: Color(0xFFFFF0D6),
    surfaceAlt: Color(0xFFD6B98C),
    primary: Color(0xFF14243A),
    secondary: Color(0xFF315D6C),
    accent: Color(0xFFE39A35),
    text: Color(0xFF221A14),
    muted: Color(0xFF6E5B4A),
  ),
  StudyVisualTheme(
    id: 'gardenMatcha',
    name: 'Garden Matcha',
    description: 'Fresh greens, morning light, and calm energy.',
    emoji: '🍵',
    background: Color(0xFFE8D9B7),
    surface: Color(0xFFFFF4DC),
    surfaceAlt: Color(0xFFD9C78E),
    primary: Color(0xFF4B632B),
    secondary: Color(0xFF7D7D3F),
    accent: Color(0xFFD19A37),
    text: Color(0xFF2A2616),
    muted: Color(0xFF69623F),
  ),
  StudyVisualTheme(
    id: 'grandArchive',
    name: 'Grand Archive',
    description: 'Timeless knowledge, brass lamps, and endless inspiration.',
    emoji: '🏛️',
    background: Color(0xFFE7D1AD),
    surface: Color(0xFFFFEED1),
    surfaceAlt: Color(0xFFD9AD72),
    primary: Color(0xFF4A2712),
    secondary: Color(0xFF754A21),
    accent: Color(0xFFD08B2E),
    text: Color(0xFF2C170C),
    muted: Color(0xFF76563A),
  ),
];

// Finds a visual theme by id and falls back to the default cozy theme.
StudyVisualTheme themeById(String id) {
  return studyThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => studyThemes.first,
  );
}
