import 'package:flutter/widgets.dart';

class StudyThemeVisuals {
  const StudyThemeVisuals({
    required this.simpleImagePath,
    required this.detailImagePath,
    required this.cardImagePath,
    this.detailAlignment = Alignment.center,
  });

  final String simpleImagePath;
  final String detailImagePath;
  final String cardImagePath;
  final Alignment detailAlignment;
}

const studyThemeVisuals = {
  'cozyCafe': StudyThemeVisuals(
    simpleImagePath:
        'assets/reference/generated/cozy_cafe_simple_painterly_v1.png',
    detailImagePath: 'assets/reference/generated/cozy_cafe_painterly_v1.png',
    cardImagePath: 'assets/reference/generated/cozy_cafe_painterly_v1.png',
    detailAlignment: Alignment.center,
  ),
  'rainyLibrary': StudyThemeVisuals(
    simpleImagePath:
        'assets/reference/generated/rainy_library_simple_painterly_v1.png',
    detailImagePath:
        'assets/reference/generated/rainy_library_painterly_v1.png',
    cardImagePath: 'assets/reference/generated/rainy_library_painterly_v1.png',
    detailAlignment: Alignment.topCenter,
  ),
  'midnightCity': StudyThemeVisuals(
    simpleImagePath:
        'assets/reference/generated/midnight_city_simple_painterly_v1.png',
    detailImagePath:
        'assets/reference/generated/midnight_city_painterly_v1.png',
    cardImagePath: 'assets/reference/generated/midnight_city_painterly_v1.png',
    detailAlignment: Alignment.center,
  ),
  'gardenMatcha': StudyThemeVisuals(
    simpleImagePath:
        'assets/reference/generated/garden_matcha_simple_painterly_v1.png',
    detailImagePath:
        'assets/reference/generated/garden_matcha_painterly_v1.png',
    cardImagePath: 'assets/reference/generated/garden_matcha_painterly_v1.png',
    detailAlignment: Alignment.center,
  ),
  'grandArchive': StudyThemeVisuals(
    simpleImagePath:
        'assets/reference/generated/grand_archive_simple_painterly_v1.png',
    detailImagePath:
        'assets/reference/generated/grand_archive_painterly_v1.png',
    cardImagePath: 'assets/reference/generated/grand_archive_painterly_v1.png',
    detailAlignment: Alignment.center,
  ),
};

// Returns image metadata for the requested theme, falling back to Cozy Cafe.
StudyThemeVisuals visualsForTheme(String themeId) {
  return studyThemeVisuals[themeId] ?? studyThemeVisuals['cozyCafe']!;
}

// Returns the banner photo path used by one top-level app screen.
String screenBannerAsset(String screenId, String themeId) {
  switch (screenId) {
    case 'tasks':
      return visualsForTheme(themeId).cardImagePath;
    case 'planner':
      return 'assets/reference/generated/midnight_city_painterly_v1.png';
    case 'notes':
      return 'assets/reference/generated/rainy_library_painterly_v1.png';
    case 'shop':
      return 'assets/reference/generated/cozy_cafe_painterly_v1.png';
    default:
      return visualsForTheme(themeId).cardImagePath;
  }
}
