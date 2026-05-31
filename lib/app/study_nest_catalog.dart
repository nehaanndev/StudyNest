import 'package:flutter/material.dart';

import '../models/study_models.dart';

class StudyDecorItem {
  const StudyDecorItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.themeId,
    required this.icon,
    required this.assetPath,
    required this.baseScale,
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final String themeId;
  final IconData icon;
  final String assetPath;
  final double baseScale;
}

class StudySpaceLookOption {
  const StudySpaceLookOption({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

const studySpaceLookOptions = [
  StudySpaceLookOption(id: 'simple', title: 'Simple', icon: Icons.crop_square),
  StudySpaceLookOption(id: 'detail', title: 'Detail', icon: Icons.photo),
];

const studyThemeShopItems = [
  ShopItem(
    id: 'theme.rainyLibrary',
    title: 'Rainy Library',
    description: 'Quiet pages, gentle rain, and endless knowledge.',
    cost: 80,
    themeId: 'rainyLibrary',
    icon: '📚',
  ),
  ShopItem(
    id: 'theme.midnightCity',
    title: 'Midnight City',
    description: 'City lights, late nights, and laser focus.',
    cost: 100,
    themeId: 'midnightCity',
    icon: '🌃',
  ),
  ShopItem(
    id: 'theme.gardenMatcha',
    title: 'Garden Matcha',
    description: 'Fresh greens, morning light, and calm energy.',
    cost: 70,
    themeId: 'gardenMatcha',
    icon: '🍵',
  ),
  ShopItem(
    id: 'theme.grandArchive',
    title: 'Grand Archive',
    description: 'Timeless knowledge, brass lamps, and endless inspiration.',
    cost: 120,
    themeId: 'grandArchive',
    icon: '🏛️',
  ),
];

const studyDecorItems = [
  StudyDecorItem(
    id: 'decor.cozyCafe.mug',
    title: 'Cozy Mug',
    description: 'A warm table mug for the cafe desk.',
    cost: 25,
    themeId: 'cozyCafe',
    icon: Icons.coffee,
    assetPath: 'assets/decor/generated/coffee_mug_painterly_v1.png',
    baseScale: 0.17,
  ),
  StudyDecorItem(
    id: 'decor.cozyCafe.brassLamp',
    title: 'Brass Desk Lamp',
    description: 'A focused amber cone light for late cafe sessions.',
    cost: 40,
    themeId: 'cozyCafe',
    icon: Icons.light,
    assetPath: 'assets/decor/generated/brass_desk_lamp_painterly_v1.png',
    baseScale: 0.23,
  ),
  StudyDecorItem(
    id: 'decor.cozyCafe.pastryTray',
    title: 'Pastry Tray',
    description: 'Croissants and cafe snacks for the front counter.',
    cost: 35,
    themeId: 'cozyCafe',
    icon: Icons.bakery_dining,
    assetPath: 'assets/decor/generated/pastry_plate_painterly_v1.png',
    baseScale: 0.21,
  ),
  StudyDecorItem(
    id: 'decor.rainyLibrary.greenLamp',
    title: 'Brass Reading Lamp',
    description: 'A classic library glow for the reading table.',
    cost: 45,
    themeId: 'rainyLibrary',
    icon: Icons.lightbulb,
    assetPath: 'assets/decor/generated/brass_desk_lamp_painterly_v1.png',
    baseScale: 0.20,
  ),
  StudyDecorItem(
    id: 'decor.rainyLibrary.velvetChair',
    title: 'Vintage Clock',
    description: 'A brass clock for quiet reading blocks.',
    cost: 35,
    themeId: 'rainyLibrary',
    icon: Icons.access_time,
    assetPath: 'assets/decor/generated/vintage_clock_painterly_v1.png',
    baseScale: 0.19,
  ),
  StudyDecorItem(
    id: 'decor.rainyLibrary.bookStack',
    title: 'Annotated Book Stack',
    description: 'Layered books and notes for rainy review blocks.',
    cost: 30,
    themeId: 'rainyLibrary',
    icon: Icons.menu_book,
    assetPath: 'assets/decor/generated/book_stack_painterly_v1.png',
    baseScale: 0.22,
  ),
  StudyDecorItem(
    id: 'decor.midnightCity.neonSign',
    title: 'Monitor Light',
    description: 'A warm screen bar for late-night focus.',
    cost: 50,
    themeId: 'midnightCity',
    icon: Icons.light,
    assetPath: 'assets/decor/generated/monitor_light_painterly_v1.png',
    baseScale: 0.23,
  ),
  StudyDecorItem(
    id: 'decor.midnightCity.dualMonitor',
    title: 'Mechanical Keyboard',
    description: 'A compact keyboard with cozy city-desk glow.',
    cost: 60,
    themeId: 'midnightCity',
    icon: Icons.desktop_windows,
    assetPath: 'assets/decor/generated/mechanical_keyboard_painterly_v1.png',
    baseScale: 0.25,
  ),
  StudyDecorItem(
    id: 'decor.midnightCity.deskCar',
    title: 'Headphones',
    description: 'Soft brown headphones for night coding sessions.',
    cost: 30,
    themeId: 'midnightCity',
    icon: Icons.headphones,
    assetPath: 'assets/decor/generated/headphones_painterly_v1.png',
    baseScale: 0.20,
  ),
  StudyDecorItem(
    id: 'decor.gardenMatcha.fern',
    title: 'Booth Fern',
    description: 'Soft green leaves for the glass cafe corner.',
    cost: 35,
    themeId: 'gardenMatcha',
    icon: Icons.local_florist,
    assetPath: 'assets/decor/generated/potted_plant_painterly_v1.png',
    baseScale: 0.23,
  ),
  StudyDecorItem(
    id: 'decor.gardenMatcha.matchaCup',
    title: 'Iced Matcha',
    description: 'A calm green drink on the laptop table.',
    cost: 25,
    themeId: 'gardenMatcha',
    icon: Icons.local_drink,
    assetPath: 'assets/decor/generated/matcha_cup_painterly_v1.png',
    baseScale: 0.18,
  ),
  StudyDecorItem(
    id: 'decor.gardenMatcha.earbuds',
    title: 'Candle',
    description: 'A tiny warm flame for a calm green desk.',
    cost: 30,
    themeId: 'gardenMatcha',
    icon: Icons.local_fire_department,
    assetPath: 'assets/decor/generated/candle_painterly_v1.png',
    baseScale: 0.16,
  ),
  StudyDecorItem(
    id: 'decor.grandArchive.brassLamp',
    title: 'Archive Lamp',
    description: 'A brass lamp for long reading tables.',
    cost: 50,
    themeId: 'grandArchive',
    icon: Icons.light,
    assetPath: 'assets/decor/generated/brass_desk_lamp_painterly_v1.png',
    baseScale: 0.22,
  ),
  StudyDecorItem(
    id: 'decor.grandArchive.bookStack',
    title: 'Rare Book Stack',
    description: 'Leather-bound references for deep research.',
    cost: 35,
    themeId: 'grandArchive',
    icon: Icons.menu_book,
    assetPath: 'assets/decor/generated/book_stack_painterly_v1.png',
    baseScale: 0.22,
  ),
  StudyDecorItem(
    id: 'decor.grandArchive.plant',
    title: 'Pen Holder',
    description: 'A carved desk cup with pens for archive notes.',
    cost: 35,
    themeId: 'grandArchive',
    icon: Icons.edit,
    assetPath: 'assets/decor/generated/pen_holder_painterly_v1.png',
    baseScale: 0.20,
  ),
  StudyDecorItem(
    id: 'decor.grandArchive.clock',
    title: 'Vintage Clock',
    description: 'A warm brass clock for timeless study sessions.',
    cost: 40,
    themeId: 'grandArchive',
    icon: Icons.access_time,
    assetPath: 'assets/decor/generated/vintage_clock_painterly_v1.png',
    baseScale: 0.19,
  ),
];

// Returns a starter normalized room position for a decor item.
Offset defaultDecorPositionFor(String itemId) {
  switch (itemId) {
    case 'decor.cozyCafe.brassLamp':
      return const Offset(0.20, 0.18);
    case 'decor.cozyCafe.mug':
      return const Offset(0.57, 0.66);
    case 'decor.cozyCafe.pastryTray':
      return const Offset(0.24, 0.74);
    case 'decor.rainyLibrary.greenLamp':
      return const Offset(0.46, 0.53);
    case 'decor.rainyLibrary.velvetChair':
      return const Offset(0.18, 0.76);
    case 'decor.rainyLibrary.bookStack':
      return const Offset(0.68, 0.67);
    case 'decor.midnightCity.neonSign':
      return const Offset(0.76, 0.20);
    case 'decor.midnightCity.dualMonitor':
      return const Offset(0.46, 0.52);
    case 'decor.midnightCity.deskCar':
      return const Offset(0.28, 0.72);
    case 'decor.gardenMatcha.fern':
      return const Offset(0.80, 0.55);
    case 'decor.gardenMatcha.matchaCup':
      return const Offset(0.42, 0.67);
    case 'decor.gardenMatcha.earbuds':
      return const Offset(0.30, 0.72);
    case 'decor.grandArchive.brassLamp':
      return const Offset(0.22, 0.56);
    case 'decor.grandArchive.bookStack':
      return const Offset(0.58, 0.68);
    case 'decor.grandArchive.plant':
      return const Offset(0.78, 0.55);
    default:
      return const Offset(0.62, 0.70);
  }
}

// Finds one decor item by id for previews, overlays, and persistence helpers.
StudyDecorItem decorItemById(String itemId) {
  return studyDecorItems.firstWhere((item) => item.id == itemId);
}
