import 'package:flutter/widgets.dart';

class StudyThemeVisuals {
  const StudyThemeVisuals({
    required this.detailImagePath,
    required this.cardImagePath,
    this.detailAlignment = Alignment.center,
  });

  final String detailImagePath;
  final String cardImagePath;
  final Alignment detailAlignment;
}

const studyThemeVisuals = {
  'cozyCafe': StudyThemeVisuals(
    detailImagePath: 'assets/reference/cozy_cafe_detail.jpg',
    cardImagePath: 'assets/reference/cafe_counter_banner.jpg',
    detailAlignment: Alignment.center,
  ),
  'rainyLibrary': StudyThemeVisuals(
    detailImagePath: 'assets/reference/rainy_library_detail.jpg',
    cardImagePath: 'assets/reference/library_banner.jpg',
    detailAlignment: Alignment.topCenter,
  ),
  'midnightCity': StudyThemeVisuals(
    detailImagePath: 'assets/reference/midnight_city_detail.jpg',
    cardImagePath: 'assets/reference/city_day_banner.jpg',
    detailAlignment: Alignment.center,
  ),
  'gardenMatcha': StudyThemeVisuals(
    detailImagePath: 'assets/reference/garden_matcha_detail.png',
    cardImagePath: 'assets/reference/night_cafe_banner.jpg',
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
      return 'assets/reference/city_day_banner.jpg';
    case 'notes':
      return 'assets/reference/library_banner.jpg';
    case 'shop':
      return 'assets/reference/cafe_counter_banner.jpg';
    default:
      return visualsForTheme(themeId).cardImagePath;
  }
}
