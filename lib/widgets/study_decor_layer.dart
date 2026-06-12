import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';

class StudyDecorPreview extends StatelessWidget {
  const StudyDecorPreview({
    super.key,
    required this.item,
    this.size = 52,
    this.backgroundColor,
    this.paddingFactor = 0.12,
  });

  final StudyDecorItem item;
  final double size;
  final Color? backgroundColor;
  final double paddingFactor;

  // Builds a framed decor preview using the same asset shown inside the room.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * paddingFactor),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DecorSpriteImage(item: item),
    );
  }
}

class StudyDecorLayer extends StatelessWidget {
  const StudyDecorLayer({
    super.key,
    required this.decorItems,
    required this.decorPositions,
    this.sceneHeight,
  });

  final List<StudyDecorItem> decorItems;
  final Map<String, Offset> decorPositions;
  final double? sceneHeight;

  // Builds the positioned room decor sprites above the painted background.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = sceneHeight ?? constraints.maxHeight;
        final layeredItems = [...decorItems]
          ..sort((a, b) {
            final aOffset =
                decorPositions[a.id] ?? defaultDecorPositionFor(a.id);
            final bOffset =
                decorPositions[b.id] ?? defaultDecorPositionFor(b.id);
            return aOffset.dy.compareTo(bOffset.dy);
          });

        return Stack(
          children: [
            for (final item in layeredItems)
              _PositionedDecor(
                item: item,
                position:
                    decorPositions[item.id] ?? defaultDecorPositionFor(item.id),
                sceneSize: Size(width, height),
              ),
          ],
        );
      },
    );
  }
}

class _PositionedDecor extends StatelessWidget {
  const _PositionedDecor({
    required this.item,
    required this.position,
    required this.sceneSize,
  });

  final StudyDecorItem item;
  final Offset position;
  final Size sceneSize;

  // Builds one decor sprite at its normalized room position.
  @override
  Widget build(BuildContext context) {
    final size = (sceneSize.width * item.baseScale * 0.86).clamp(42.0, 98.0);
    final left = position.dx * sceneSize.width - size / 2;
    final top = position.dy * sceneSize.height - size * 0.72;

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: DecorSpriteImage(item: item),
    );
  }
}

class DecorSpriteImage extends StatelessWidget {
  const DecorSpriteImage({super.key, required this.item});

  final StudyDecorItem item;

  // Builds the decor PNG overlay with a graceful pre-asset fallback chip.
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      item.assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _DecorFallbackChip(item: item);
      },
    );
  }
}

class _DecorFallbackChip extends StatelessWidget {
  const _DecorFallbackChip({required this.item});

  final StudyDecorItem item;

  // Builds the rarity-tinted stand-in shown until the PNG asset is bundled.
  @override
  Widget build(BuildContext context) {
    final accent = item.rarity.color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
              border: Border.all(
                color: accent.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: Icon(item.icon, size: side * 0.5, color: accent),
          ),
        );
      },
    );
  }
}
