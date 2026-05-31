import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import 'cozy_widgets.dart';

class StudyStationBanner extends StatelessWidget {
  const StudyStationBanner({
    super.key,
    required this.title,
    required this.detail,
    required this.metric,
    required this.icon,
    required this.imagePath,
    this.imageAlignment = Alignment.center,
  });

  final String title;
  final String detail;
  final String metric;
  final IconData icon;
  final String imagePath;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return CozyCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 152,
          child: Stack(
            children: [
              // Room illustration
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                ),
              ),
              // Gradient overlay — stronger on dark themes
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              // Metric pill — top left
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    metric,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: theme.text,
                    ),
                  ),
                ),
              ),
              // Title + detail panel — bottom
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.surface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: theme.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: theme.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                color: theme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
