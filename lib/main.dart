import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/study_nest_scope.dart';
import 'app/study_nest_state.dart';
import 'firebase_options.dart';
import 'screens/habits_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/tasks_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final appState = await StudyNestState.load();
  runApp(StudyNestApp(appState: appState));
}

class StudyNestApp extends StatelessWidget {
  const StudyNestApp({super.key, required this.appState});

  final StudyNestState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return StudyNestScope(
          state: appState,
          child: MaterialApp(
            key: ValueKey(appState.userId ?? 'local-user'),
            title: 'StudyNest',
            debugShowCheckedModeBanner: false,
            theme: appState.selectedTheme.toThemeData(),
            home: const MainScreen(),
          ),
        );
      },
    );
  }
}

// Tab indices for the 6-item bottom nav bar.
// 0=Home  1=Tasks  2=Focus  3=Calendar  4=Notes  5=Shop
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  // Allows child screens (e.g. HomeScreen) to programmatically switch tabs.
  void _navigate(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    // 5 primary screens in the IndexedStack — More opens a sheet, not a screen.
    final screens = [
      HomeScreen(onNavigate: _navigate), // 0
      const TasksScreen(), // 1
      const PomodoroScreen(), // 2
      const PlannerScreen(), // 3
      const NotesScreen(), // 4
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.background.withValues(alpha: 0.78),
              theme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: NavigationBar(
                    // Index 5 is the virtual "More" slot — tapping it shows a
                    // bottom sheet instead of switching the IndexedStack.
                    selectedIndex: _index,
                    onDestinationSelected: (i) {
                      if (i == 5) {
                        _showMoreSheet(context);
                      } else {
                        setState(() => _index = i);
                      }
                    },
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
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
                        label: 'Calendar',
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
      ),
    );
  }

  // Opens the More bottom sheet with Shop, Habits, and Profile.
  void _showMoreSheet(BuildContext context) {
    final theme = StudyNestScope.read(context).selectedTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            const SizedBox(height: 20),
            Row(
              children: [
                _MoreTile(
                  emoji: '🛍️',
                  label: 'Shop',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    );
                  },
                ),
                _MoreTile(
                  emoji: '🔥',
                  label: 'Habits',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HabitsScreen()),
                    );
                  },
                ),
                _MoreTile(
                  emoji: '👤',
                  label: 'Profile',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tile used inside the More bottom sheet.
class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
