import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_session.dart';
import '../theme/study_theme.dart';
import 'auth/welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final isSignedIn =
        state.authStatus == StudyNestAuthStatus.ready && !state.isAnonymousUser;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.background,
              Color.alphaBlend(
                theme.primary.withValues(alpha: 0.06),
                theme.background,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        foregroundColor: theme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    // Account section
                    _SectionHeader(title: 'Account'),
                    if (!isSignedIn)
                      _SettingsTile(
                        icon: Icons.login_rounded,
                        title: 'Sign In or Create Account',
                        subtitle: 'Sync your data across devices',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WelcomeScreen(
                              onDismiss: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      _SettingsInfoTile(
                        icon: Icons.person_outline,
                        title: 'Email',
                        value: state.userEmail ?? '—',
                      ),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        textColor: Colors.red.shade400,
                        onTap: () => _confirmSignOut(context),
                      ),
                    ],

                    const SizedBox(height: 8),
                    _SectionHeader(title: 'Appearance'),
                    _ThemeSelector(),

                    const SizedBox(height: 8),
                    _SectionHeader(title: 'Data'),
                    _SettingsTile(
                      icon: Icons.delete_outline,
                      title: 'Reset Progress',
                      subtitle: 'Clear all tasks, notes, and coins',
                      textColor: Colors.red.shade400,
                      onTap: () => _confirmReset(context),
                    ),

                    const SizedBox(height: 8),
                    _SectionHeader(title: 'About'),
                    _SettingsInfoTile(
                      icon: Icons.info_outline,
                      title: 'Version',
                      value: '1.0.0',
                    ),
                    _SettingsInfoTile(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Sync Status',
                      value: _syncStatusLabel(state.syncStatus),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _syncStatusLabel(StudyNestSyncStatus status) {
    switch (status) {
      case StudyNestSyncStatus.idle:
        return 'Up to date';
      case StudyNestSyncStatus.syncing:
        return 'Syncing…';
      case StudyNestSyncStatus.offline:
        return 'Offline';
      case StudyNestSyncStatus.error:
        return 'Sync error';
      case StudyNestSyncStatus.disabled:
        return 'Local only';
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your data is saved. You can sign back in anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await StudyNestScope.read(context).signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This will permanently delete all your tasks, notes, habits, coins, and planner events. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset is not yet implemented.')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: theme.muted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final color = textColor ?? theme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.surface.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primary.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: theme.muted, fontSize: 12),
              )
            : null,
        trailing: onTap != null
            ? Icon(Icons.chevron_right, color: theme.muted, size: 20)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.surface.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primary.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.primary, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: TextStyle(color: theme.muted, fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.surface.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: theme.primary, size: 22),
                const SizedBox(width: 12),
                const Text(
                  'Theme',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in studyThemes)
                  _ThemeChip(
                    theme: t,
                    selected: t.id == state.selectedTheme.id,
                    owned: state.ownsTheme(t.id),
                    onTap: state.ownsTheme(t.id)
                        ? () => state.applyTheme(t.id)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.selected,
    required this.owned,
    this.onTap,
  });

  final StudyVisualTheme theme;
  final bool selected;
  final bool owned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: selected ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.primary
                : theme.primary.withValues(alpha: 0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(theme.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: owned
                    ? theme.primary
                    : theme.primary.withValues(alpha: 0.5),
              ),
            ),
            if (!owned) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.lock_outline,
                size: 12,
                color: theme.primary.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
