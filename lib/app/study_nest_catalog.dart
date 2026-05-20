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
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final String themeId;
  final IconData icon;
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
  StudySpaceLookOption(
    id: 'reference',
    title: 'Reference',
    icon: Icons.photo_library,
  ),
];

const studyThemeShopItems = [
  ShopItem(
    id: 'theme.rainyLibrary',
    title: 'Rainy Library',
    description: 'Mahogany shelves, green lamps, carved arches, and rain.',
    cost: 80,
    themeId: 'rainyLibrary',
    icon: '📚',
  ),
  ShopItem(
    id: 'theme.midnightCity',
    title: 'Midnight City',
    description: 'Blue skyline glass, code screens, balcony lights, and neon.',
    cost: 100,
    themeId: 'midnightCity',
    icon: '🌃',
  ),
  ShopItem(
    id: 'theme.gardenMatcha',
    title: 'Garden Matcha',
    description: 'Glass cafe booths, matcha greens, laptop glow, and plants.',
    cost: 70,
    themeId: 'gardenMatcha',
    icon: '🍵',
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
  ),
  StudyDecorItem(
    id: 'decor.cozyCafe.brassLamp',
    title: 'Brass Desk Lamp',
    description: 'A focused amber cone light for late cafe sessions.',
    cost: 40,
    themeId: 'cozyCafe',
    icon: Icons.light,
  ),
  StudyDecorItem(
    id: 'decor.cozyCafe.pastryTray',
    title: 'Pastry Tray',
    description: 'Croissants and cafe snacks for the front counter.',
    cost: 35,
    themeId: 'cozyCafe',
    icon: Icons.bakery_dining,
  ),
  StudyDecorItem(
    id: 'decor.rainyLibrary.greenLamp',
    title: 'Green Banker Lamp',
    description: 'A classic library glow for the reading table.',
    cost: 45,
    themeId: 'rainyLibrary',
    icon: Icons.lightbulb,
  ),
  StudyDecorItem(
    id: 'decor.rainyLibrary.velvetChair',
    title: 'Velvet Reading Chair',
    description: 'A deep green chair tucked beside the shelves.',
    cost: 55,
    themeId: 'rainyLibrary',
    icon: Icons.chair,
  ),
  StudyDecorItem(
    id: 'decor.rainyLibrary.bookStack',
    title: 'Annotated Book Stack',
    description: 'Layered books and notes for rainy review blocks.',
    cost: 30,
    themeId: 'rainyLibrary',
    icon: Icons.menu_book,
  ),
  StudyDecorItem(
    id: 'decor.midnightCity.neonSign',
    title: 'Neon Focus Sign',
    description: 'A tiny skyline sign with night-work energy.',
    cost: 50,
    themeId: 'midnightCity',
    icon: Icons.signpost,
  ),
  StudyDecorItem(
    id: 'decor.midnightCity.dualMonitor',
    title: 'Dual Monitor Glow',
    description: 'Extra code screens for the city desk.',
    cost: 60,
    themeId: 'midnightCity',
    icon: Icons.desktop_windows,
  ),
  StudyDecorItem(
    id: 'decor.midnightCity.deskCar',
    title: 'Desk Toy Car',
    description: 'A small yellow car parked beside the laptop.',
    cost: 30,
    themeId: 'midnightCity',
    icon: Icons.directions_car,
  ),
  StudyDecorItem(
    id: 'decor.gardenMatcha.fern',
    title: 'Booth Fern',
    description: 'Soft green leaves for the glass cafe corner.',
    cost: 35,
    themeId: 'gardenMatcha',
    icon: Icons.local_florist,
  ),
  StudyDecorItem(
    id: 'decor.gardenMatcha.matchaCup',
    title: 'Iced Matcha',
    description: 'A calm green drink on the laptop table.',
    cost: 25,
    themeId: 'gardenMatcha',
    icon: Icons.local_drink,
  ),
  StudyDecorItem(
    id: 'decor.gardenMatcha.earbuds',
    title: 'Earbud Case',
    description: 'A small quiet-focus accessory beside the notebook.',
    cost: 30,
    themeId: 'gardenMatcha',
    icon: Icons.earbuds,
  ),
];

// Returns a starter normalized room position for a decor item.
Offset defaultDecorPositionFor(String itemId) {
  switch (itemId) {
    case 'decor.cozyCafe.brassLamp':
      return const Offset(0.30, 0.30);
    case 'decor.cozyCafe.pastryTray':
      return const Offset(0.35, 0.72);
    case 'decor.rainyLibrary.greenLamp':
      return const Offset(0.48, 0.58);
    case 'decor.rainyLibrary.velvetChair':
      return const Offset(0.25, 0.72);
    case 'decor.rainyLibrary.bookStack':
      return const Offset(0.66, 0.64);
    case 'decor.midnightCity.neonSign':
      return const Offset(0.76, 0.26);
    case 'decor.midnightCity.dualMonitor':
      return const Offset(0.45, 0.48);
    case 'decor.midnightCity.deskCar':
      return const Offset(0.22, 0.70);
    case 'decor.gardenMatcha.fern':
      return const Offset(0.78, 0.48);
    case 'decor.gardenMatcha.matchaCup':
      return const Offset(0.38, 0.65);
    case 'decor.gardenMatcha.earbuds':
      return const Offset(0.28, 0.72);
    default:
      return const Offset(0.62, 0.70);
  }
}
