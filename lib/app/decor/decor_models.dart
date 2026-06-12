import 'package:flutter/material.dart';

/// Collectible rarity tiers that drive pricing bands and shop styling.
enum DecorRarity { common, rare, epic, legendary }

extension DecorRarityDisplay on DecorRarity {
  // Returns the shop-facing label for this rarity tier.
  String get label {
    switch (this) {
      case DecorRarity.common:
        return 'Common';
      case DecorRarity.rare:
        return 'Rare';
      case DecorRarity.epic:
        return 'Epic';
      case DecorRarity.legendary:
        return 'Legendary';
    }
  }

  // Returns the accent color used for rarity tags, borders, and glows.
  Color get color {
    switch (this) {
      case DecorRarity.common:
        return const Color(0xFF8D7B68);
      case DecorRarity.rare:
        return const Color(0xFF4E84B5);
      case DecorRarity.epic:
        return const Color(0xFF8E66C9);
      case DecorRarity.legendary:
        return const Color(0xFFD09A18);
    }
  }

  // Reports whether shop cards should render a soft collectible glow.
  bool get hasGlow {
    return this == DecorRarity.epic || this == DecorRarity.legendary;
  }
}

/// Designated room regions that keep decor placed where it looks natural.
enum DecorZone { desk, wall, floor, free }

extension DecorZoneBounds on DecorZone {
  // Returns the normalized rectangle decor in this zone may occupy.
  Rect get bounds {
    switch (this) {
      case DecorZone.desk:
        return const Rect.fromLTRB(0.10, 0.40, 0.90, 0.78);
      case DecorZone.wall:
        return const Rect.fromLTRB(0.10, 0.12, 0.90, 0.45);
      case DecorZone.floor:
        return const Rect.fromLTRB(0.10, 0.64, 0.90, 0.88);
      case DecorZone.free:
        return const Rect.fromLTRB(0.08, 0.12, 0.92, 0.88);
    }
  }

  // Clamps a normalized room position into this zone's rectangle.
  Offset clampPosition(Offset position) {
    final zoneRect = bounds;
    return Offset(
      position.dx.clamp(zoneRect.left, zoneRect.right).toDouble(),
      position.dy.clamp(zoneRect.top, zoneRect.bottom).toDouble(),
    );
  }
}

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
    required this.rarity,
    required this.zone,
    required this.defaultPosition,
  });

  final String id;
  final String title;
  final String description;
  final int cost;

  /// Owning room theme id; every decoration belongs to exactly one theme.
  final String themeId;

  /// Fallback glyph shown until the item's PNG asset is bundled.
  final IconData icon;
  final String assetPath;
  final double baseScale;
  final DecorRarity rarity;

  /// Placement region used to keep the item naturally positioned.
  final DecorZone zone;

  /// Starter normalized room position before the user drags the item.
  final Offset defaultPosition;
}
