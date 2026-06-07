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
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
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
      // Explicitly remove decorations so text never inherits underlines.
      textTheme: baseTheme.textTheme
          .apply(bodyColor: text, displayColor: text, decorationColor: text)
          .copyWith(
            bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
              color: text,
              decoration: TextDecoration.none,
            ),
            bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
              color: text,
              decoration: TextDecoration.none,
            ),
            bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
              color: text,
              decoration: TextDecoration.none,
            ),
            labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
              color: text,
              decoration: TextDecoration.none,
            ),
            labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
              color: text,
              decoration: TextDecoration.none,
            ),
            labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
              color: text,
              decoration: TextDecoration.none,
            ),
          ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.85),
        indicatorColor: accent.withValues(alpha: 0.20),
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
    background: Color(0xFF0D1117),
    surface: Color(0xFF1A1208),
    surfaceAlt: Color(0xFF251A0C),
    primary: Color(0xFFFFB347),
    secondary: Color(0xFFD4956B),
    accent: Color(0xFFF4C86A),
    text: Color(0xFFFFF3E0),
    muted: Color(0xFFA89070),
  ),
  StudyVisualTheme(
    id: 'rainyLibrary',
    name: 'Rainy Library',
    description: 'Quiet pages, gentle rain, and endless knowledge.',
    emoji: '📚',
    background: Color(0xFF090E18),
    surface: Color(0xFF0F1624),
    surfaceAlt: Color(0xFF172033),
    primary: Color(0xFF7EB8C4),
    secondary: Color(0xFF5A8A96),
    accent: Color(0xFFE8B86D),
    text: Color(0xFFE8E0D0),
    muted: Color(0xFF8A9BAA),
  ),
  StudyVisualTheme(
    id: 'midnightCity',
    name: 'Midnight City',
    description: 'City lights, late nights, and laser focus.',
    emoji: '🌃',
    background: Color(0xFF080D18),
    surface: Color(0xFF0D1525),
    surfaceAlt: Color(0xFF141F35),
    primary: Color(0xFF6B9FE4),
    secondary: Color(0xFF4A7AC8),
    accent: Color(0xFFFFB347),
    text: Color(0xFFF0EFFF),
    muted: Color(0xFF7A8BAA),
  ),
  StudyVisualTheme(
    id: 'gardenMatcha',
    name: 'Garden Matcha',
    description: 'Fresh greens, morning light, and calm energy.',
    emoji: '🍵',
    background: Color(0xFF091209),
    surface: Color(0xFF0F1A10),
    surfaceAlt: Color(0xFF162318),
    primary: Color(0xFF7ACC7A),
    secondary: Color(0xFF5A9E5A),
    accent: Color(0xFFD4C46A),
    text: Color(0xFFEFF5E8),
    muted: Color(0xFF849A84),
  ),
  StudyVisualTheme(
    id: 'grandArchive',
    name: 'Grand Archive',
    description: 'Timeless knowledge, brass lamps, and endless inspiration.',
    emoji: '🏛️',
    background: Color(0xFF0E0A04),
    surface: Color(0xFF1A1208),
    surfaceAlt: Color(0xFF231808),
    primary: Color(0xFFD4A855),
    secondary: Color(0xFF8B6E35),
    accent: Color(0xFFF4C86A),
    text: Color(0xFFFFF0D0),
    muted: Color(0xFFA08060),
  ),
];

// Finds a visual theme by id and falls back to the default cozy theme.
StudyVisualTheme themeById(String id) {
  return studyThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => studyThemes.first,
  );
}
