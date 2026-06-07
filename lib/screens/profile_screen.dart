import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_session.dart';
import '../widgets/cozy_widgets.dart';
import 'auth/google_sign_in_button.dart';
import 'auth/welcome_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final isSignedIn = state.authStatus == StudyNestAuthStatus.ready &&
        !state.isAnonymousUser;

    return CozyPage(
      title: 'Profile',
      subtitle: isSignedIn ? 'Your account & stats.' : 'Create an account to sync your data.',
      child: Column(
        children: [
          // Account card
          _AccountCard(isSignedIn: isSignedIn),
          const SizedBox(height: 16),
          // Stats card
          _StatsCard(),
          const SizedBox(height: 16),
          // Settings shortcut
          _MenuTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          if (!isSignedIn) ...[
            // Google sign-in shown prominently for anonymous users
            GoogleSignInButton(
              label: 'Continue with Google',
              onSuccess: () {},
              onError: (msg) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg))),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.email_outlined,
              label: 'Sign in with Email',
              onTap: () => _showWelcome(context),
            ),
          ] else
            _MenuTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              onTap: () => _confirmSignOut(context),
              destructive: true,
            ),
        ],
      ),
    );
  }

  void _showWelcome(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WelcomeScreen(onDismiss: () => Navigator.of(context).pop()),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your data is saved. You can sign back in anytime.'),
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
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.isSignedIn});
  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isSignedIn ? _avatarInitial(state.userEmail) : '👤',
                style: TextStyle(
                  fontSize: isSignedIn ? 22 : 28,
                  color: theme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSignedIn
                      ? (state.userDisplayName ?? state.userEmail ?? 'Signed In')
                      : 'Anonymous',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSignedIn
                      ? (state.userEmail ?? '')
                      : 'Not synced to the cloud',
                  style: TextStyle(color: theme.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSignedIn
                  ? Colors.green.withValues(alpha: 0.15)
                  : theme.muted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isSignedIn ? 'Synced' : 'Local',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSignedIn ? Colors.green : theme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _avatarInitial(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }
}

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;

    final completedTasks = state.completedTaskCount;
    final openTasks = state.openTaskCount;
    final coinBalance = state.coinBalance;
    final habitStreaks = state.habits.fold(0, (sum, h) => sum + h.streak);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(label: 'Tasks Done', value: '$completedTasks', icon: '✅'),
              _StatItem(label: 'Open Tasks', value: '$openTasks', icon: '📋'),
              _StatItem(label: 'Coins', value: '$coinBalance', icon: '🪙'),
              _StatItem(label: 'Streak Days', value: '$habitStreaks', icon: '🔥'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: theme.muted),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final color = destructive ? Colors.red.shade400 : theme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.surface.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primary.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.muted),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
