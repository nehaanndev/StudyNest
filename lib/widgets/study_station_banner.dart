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
  });

  final String title;
  final String detail;
  final String metric;
  final IconData icon;

  // Builds a feature-specific room station banner for non-home tabs.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return CozyCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 118,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  theme.accent.withValues(alpha: 0.18),
                  theme.surface,
                ),
                theme.surfaceAlt,
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _StationBackdrop()),
              Positioned(
                left: 14,
                top: 14,
                bottom: 14,
                child: _StationIcon(icon: icon),
              ),
              Positioned(
                left: 86,
                right: 96,
                top: 20,
                bottom: 20,
                child: _StationCopy(title: title, detail: detail),
              ),
              Positioned(
                right: 12,
                top: 16,
                bottom: 16,
                child: _StationMetric(metric: metric),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationBackdrop extends StatelessWidget {
  const _StationBackdrop();

  // Builds decorative furniture blocks for a compact room station.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Stack(
      children: [
        Positioned(
          right: 24,
          top: 15,
          child: Container(
            width: 94,
            height: 42,
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.46),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primary.withValues(alpha: 0.28)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 40,
            color: theme.primary.withValues(alpha: 0.10),
          ),
        ),
        Positioned(
          right: 132,
          bottom: 20,
          child: Container(
            width: 72,
            height: 28,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Positioned(
          right: 42,
          bottom: 26,
          child: Icon(
            Icons.local_florist,
            color: theme.secondary.withValues(alpha: 0.42),
            size: 46,
          ),
        ),
      ],
    );
  }
}

class _StationIcon extends StatelessWidget {
  const _StationIcon({required this.icon});

  final IconData icon;

  // Builds the large icon badge for a feature station.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accent.withValues(alpha: 0.36)),
      ),
      child: Icon(icon, color: theme.accent, size: 29),
    );
  }
}

class _StationCopy extends StatelessWidget {
  const _StationCopy({required this.title, required this.detail});

  final String title;
  final String detail;

  // Builds the text copy for a feature station banner.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.muted, height: 1.25),
        ),
      ],
    );
  }
}

class _StationMetric extends StatelessWidget {
  const _StationMetric({required this.metric});

  final String metric;

  // Builds the metric chip pinned to a station banner.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      width: 76,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        metric,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}
