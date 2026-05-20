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
        backgroundColor: surface.withValues(alpha: 0.98),
        indicatorColor: accent.withValues(alpha: 0.22),
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
    description: 'Warm wood, latte foam, and soft lamps.',
    emoji: '☕',
    background: Color(0xFFF6D8B4),
    surface: Color(0xFFFFF8EC),
    surfaceAlt: Color(0xFFFFE9C8),
    primary: Color(0xFFB97145),
    secondary: Color(0xFF73985E),
    accent: Color(0xFFF0A72C),
    text: Color(0xFF352013),
    muted: Color(0xFF7E6653),
  ),
  StudyVisualTheme(
    id: 'rainyLibrary',
    name: 'Rainy Library',
    description: 'Mahogany shelves, green lamps, and quiet rain.',
    emoji: '📚',
    background: Color(0xFFD6C0A5),
    surface: Color(0xFFFFF7E8),
    surfaceAlt: Color(0xFFE4D1AF),
    primary: Color(0xFF6F432B),
    secondary: Color(0xFF3F6D54),
    accent: Color(0xFFD6A34D),
    text: Color(0xFF2D1D16),
    muted: Color(0xFF705C4E),
  ),
  StudyVisualTheme(
    id: 'midnightCity',
    name: 'Midnight City',
    description: 'Blue glass skyline focus with warm desk light.',
    emoji: '🌃',
    background: Color(0xFFB9C8D6),
    surface: Color(0xFFF5F1E9),
    surfaceAlt: Color(0xFFD8E4EE),
    primary: Color(0xFF243C55),
    secondary: Color(0xFF8D6B52),
    accent: Color(0xFFE9A63D),
    text: Color(0xFF1F252B),
    muted: Color(0xFF5F6B73),
  ),
  StudyVisualTheme(
    id: 'gardenMatcha',
    name: 'Garden Matcha',
    description: 'Matcha greens, glass booths, and laptop glow.',
    emoji: '🍵',
    background: Color(0xFFDCE6C4),
    surface: Color(0xFFFFF8E9),
    surfaceAlt: Color(0xFFC9DCA8),
    primary: Color(0xFF607A45),
    secondary: Color(0xFF9A7B4F),
    accent: Color(0xFFD4A12F),
    text: Color(0xFF26301E),
    muted: Color(0xFF647052),
  ),
];

// Finds a visual theme by id and falls back to the default cozy theme.
StudyVisualTheme themeById(String id) {
  return studyThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => studyThemes.first,
  );
}
