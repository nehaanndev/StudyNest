import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';

/// Describes every destination available from the app-level navigation.
enum StudyNestDestination {
  dashboard,
  tasks,
  focus,
  planner,
  notes,
  more,
  shop,
  habits,
  profile,
}

extension StudyNestDestinationStorage on StudyNestDestination {
  // Returns the stable value used to restore a destination after relaunch.
  String get storageId => name;

  // Restores a saved destination, safely falling back to the dashboard.
  static StudyNestDestination fromStorageId(String value) {
    for (final destination in StudyNestDestination.values) {
      if (destination.storageId == value &&
          destination != StudyNestDestination.more) {
        return destination;
      }
    }
    return StudyNestDestination.dashboard;
  }
}

/// A compact, themed bottom bar shared by the dashboard and standalone pages.
///
/// The parent owns navigation so this widget stays reusable and never creates
/// duplicate routes or competing navigation stacks.
class StudyNestBottomNavigation extends StatelessWidget {
  const StudyNestBottomNavigation({
    super.key,
    required this.selectedDestination,
    required this.onDestinationSelected,
  });

  final StudyNestDestination selectedDestination;
  final ValueChanged<StudyNestDestination> onDestinationSelected;

  // Builds the six high-frequency destinations used throughout StudyNest.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.background.withValues(alpha: 0.78), theme.background],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: NavigationBar(
                  selectedIndex: _navigationIndex(selectedDestination),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) {
                    onDestinationSelected(_primaryDestinations[index]);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.checklist_outlined),
                      selectedIcon: Icon(Icons.checklist),
                      label: 'Tasks',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.hourglass_empty_rounded),
                      selectedIcon: Icon(Icons.hourglass_bottom_rounded),
                      label: 'Focus',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: 'Plan',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.note_alt_outlined),
                      selectedIcon: Icon(Icons.note_alt),
                      label: 'Notes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view),
                      label: 'More',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Converts an app destination to its corresponding visible navigation slot.
  int _navigationIndex(StudyNestDestination destination) {
    final index = _primaryDestinations.indexOf(destination);
    return index == -1
        ? _primaryDestinations.indexOf(StudyNestDestination.more)
        : index;
  }
}

const _primaryDestinations = [
  StudyNestDestination.dashboard,
  StudyNestDestination.tasks,
  StudyNestDestination.focus,
  StudyNestDestination.planner,
  StudyNestDestination.notes,
  StudyNestDestination.more,
];

/// An explicit dashboard action for headers on pages pushed outside the root.
class StudyNestDashboardAction extends StatelessWidget {
  const StudyNestDashboardAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  // Builds an accessible icon action that always communicates its destination.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return IconButton.filledTonal(
      tooltip: 'Back to dashboard',
      onPressed: onPressed,
      icon: Icon(Icons.home_rounded, color: theme.primary),
    );
  }
}

/// Presents secondary destinations without hiding them behind unlabeled icons.
Future<void> showStudyNestMoreSheet(
  BuildContext context, {
  required ValueChanged<StudyNestDestination> onDestinationSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StudyNestMoreSheet(
      onDestinationSelected: (destination) {
        Navigator.of(sheetContext).pop();
        onDestinationSelected(destination);
      },
    ),
  );
}

/// The labeled secondary-navigation sheet for Shop, Habits, and Profile.
class StudyNestMoreSheet extends StatelessWidget {
  const StudyNestMoreSheet({super.key, required this.onDestinationSelected});

  final ValueChanged<StudyNestDestination> onDestinationSelected;

  // Builds the secondary destinations with large tap targets and text labels.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'More for your routine',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MoreDestinationTile(
                icon: Icons.storefront_outlined,
                label: 'Shop',
                onTap: () => onDestinationSelected(StudyNestDestination.shop),
              ),
              _MoreDestinationTile(
                icon: Icons.local_fire_department_outlined,
                label: 'Habits',
                onTap: () => onDestinationSelected(StudyNestDestination.habits),
              ),
              _MoreDestinationTile(
                icon: Icons.account_circle_outlined,
                label: 'Profile',
                onTap: () =>
                    onDestinationSelected(StudyNestDestination.profile),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreDestinationTile extends StatelessWidget {
  const _MoreDestinationTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  // Builds one large, labeled shortcut inside the More navigation sheet.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Material(
            color: theme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(icon, color: theme.primary, size: 30),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
