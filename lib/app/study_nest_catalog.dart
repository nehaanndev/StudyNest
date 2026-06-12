import 'package:flutter/material.dart';

import '../models/study_models.dart';
import 'decor/decor_items_cozy_cafe.dart';
import 'decor/decor_items_garden_matcha.dart';
import 'decor/decor_items_grand_archive.dart';
import 'decor/decor_items_midnight_city.dart';
import 'decor/decor_items_rainy_library.dart';
import 'decor/decor_models.dart';

export 'decor/decor_models.dart';

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

/// Every purchasable decoration, grouped into one pack per room theme.
const studyDecorItems = [
  ...cozyCafeDecorItems,
  ...rainyLibraryDecorItems,
  ...midnightCityDecorItems,
  ...gardenMatchaDecorItems,
  ...grandArchiveDecorItems,
];

/// Display order for the rarity shelves inside the decoration shop.
const decorRarityOrder = [
  DecorRarity.common,
  DecorRarity.rare,
  DecorRarity.epic,
  DecorRarity.legendary,
];

// Returns a starter normalized room position for a decor item.
Offset defaultDecorPositionFor(String itemId) {
  return decorItemOrNull(itemId)?.defaultPosition ?? const Offset(0.62, 0.70);
}

// Finds one decor item by id for previews, overlays, and persistence helpers.
StudyDecorItem decorItemById(String itemId) {
  return studyDecorItems.firstWhere((item) => item.id == itemId);
}

// Finds one decor item by id, or null when the id is no longer in the catalog.
StudyDecorItem? decorItemOrNull(String itemId) {
  for (final item in studyDecorItems) {
    if (item.id == itemId) {
      return item;
    }
  }
  return null;
}

// Sorts shelf items so cheaper, more attainable pieces appear first.
List<StudyDecorItem> sortedDecorShelf(Iterable<StudyDecorItem> items) {
  final sorted = items.toList()
    ..sort((a, b) {
      final rarityOrder = a.rarity.index.compareTo(b.rarity.index);
      if (rarityOrder != 0) {
        return rarityOrder;
      }
      return a.cost.compareTo(b.cost);
    });
  return sorted;
}
