import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';

class CozyPage extends StatelessWidget {
  const CozyPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  // Builds a full page with a dark gradient background and shared header.
  // Wraps in Scaffold to guarantee a Material ancestor for chips and dialogs
  // even when this widget is pushed as a standalone route.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.background,
              Color.alphaBlend(theme.primary.withValues(alpha: 0.08), theme.background),
              theme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pageWidth = constraints.maxWidth > 470
                  ? 430.0
                  : double.infinity;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: pageWidth,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                        decoration: TextDecoration.none,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: theme.muted,
                                    height: 1.3,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ?action,
                        ],
                      ),
                      const SizedBox(height: 18),
                      child,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CozyCard extends StatelessWidget {
  const CozyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  // Builds a glassmorphism content card floating over the dark background.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              splashColor: theme.accent.withValues(alpha: 0.08),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  // Builds a compact section heading for grouped dashboard content.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (trailing != null)
            DefaultTextStyle(
              style: TextStyle(color: theme.muted, fontSize: 13),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.coins});

  final int coins;

  // Builds the current coin balance badge.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accent.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: theme.accent,
            child: const Icon(Icons.savings, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(color: theme.text, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class CozyTag extends StatelessWidget {
  const CozyTag({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  // Builds a small metadata chip used by tasks, events, and shop cards.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.accent),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: theme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  // Builds a friendly empty-state card for sections with no records yet.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return CozyCard(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}
