import 'package:flutter/material.dart';

import '../app/study_nest_visuals.dart';

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
