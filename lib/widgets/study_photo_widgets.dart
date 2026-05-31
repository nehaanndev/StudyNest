import 'package:flutter/material.dart';

import '../app/study_nest_catalog.dart';
import '../app/study_nest_visuals.dart';
import '../theme/study_theme.dart';
import 'study_decor_layer.dart';

class StudyThemeThumbnail extends StatelessWidget {
  const StudyThemeThumbnail({
    super.key,
    required this.themeId,
    this.width = 64,
    this.height = 64,
    this.radius = 16,
  });

  final String themeId;
  final double width;
  final double height;
  final double radius;

  // Builds a cropped theme photo used by shop and study-space cards.
  @override
  Widget build(BuildContext context) {
    final visuals = visualsForTheme(themeId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          visuals.cardImagePath,
          fit: BoxFit.cover,
          alignment: visuals.detailAlignment,
        ),
      ),
    );
  }
}

class StudySceneStrip extends StatelessWidget {
  const StudySceneStrip({super.key, required this.themeId, this.height = 112});

  final String themeId;
  final double height;

  // Builds a landscape crop of a theme photo for section previews.
  @override
  Widget build(BuildContext context) {
    final visuals = visualsForTheme(themeId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              visuals.detailImagePath,
              fit: BoxFit.cover,
              alignment: visuals.detailAlignment,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudyThemeShowcaseCard extends StatelessWidget {
  const StudyThemeShowcaseCard({
    super.key,
    required this.theme,
    required this.description,
    required this.action,
    this.tags = const [],
    this.decorPreviewItems = const [],
  });

  final StudyVisualTheme theme;
  final String description;
  final Widget action;
  final List<Widget> tags;
  final List<StudyDecorItem> decorPreviewItems;

  // Builds a large immersive theme card with artwork, metadata, and decor.
  @override
  Widget build(BuildContext context) {
    final visuals = visualsForTheme(theme.id);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 238,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              visuals.cardImagePath,
              fit: BoxFit.cover,
              alignment: visuals.detailAlignment,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
                border: Border.all(color: theme.accent.withValues(alpha: 0.30)),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              right: 14,
              child: _ThemeGlassLabel(theme: theme, description: description),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _ThemeCardFooter(
                theme: theme,
                tags: tags,
                action: action,
                decorPreviewItems: decorPreviewItems,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeGlassLabel extends StatelessWidget {
  const _ThemeGlassLabel({required this.theme, required this.description});

  final StudyVisualTheme theme;
  final String description;

  // Builds the translucent title block over theme artwork.
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF241409).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    theme.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCardFooter extends StatelessWidget {
  const _ThemeCardFooter({
    required this.theme,
    required this.tags,
    required this.action,
    required this.decorPreviewItems,
  });

  final StudyVisualTheme theme;
  final List<Widget> tags;
  final Widget action;
  final List<StudyDecorItem> decorPreviewItems;

  // Builds the card footer with collectible previews and the equip action.
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in decorPreviewItems.take(3))
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D7).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.accent.withValues(alpha: 0.24),
                    ),
                  ),
                  child: StudyDecorPreview(
                    item: item,
                    size: 44,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ...tags,
            ],
          ),
        ),
        const SizedBox(width: 12),
        action,
      ],
    );
  }
}
