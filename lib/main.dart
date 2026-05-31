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
import 'screens/shop_screen.dart';
import 'screens/tasks_screen.dart';

// Starts the StudyNest Flutter application with persisted local state.
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  void _navigate(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    // Build screens lazily with navigation callback for home
    final screens = [
      HomeScreen(onNavigate: _navigate),
      const TasksScreen(),
      const PomodoroScreen(),
      const HabitsScreen(),
      const PlannerScreen(),
      const NotesScreen(),
      const ShopScreen(),
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (index) =>
                        setState(() => _index = index),
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
                        icon: Icon(Icons.local_fire_department_outlined),
                        selectedIcon: Icon(Icons.local_fire_department),
                        label: 'Habits',
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
                        icon: Icon(Icons.storefront_outlined),
                        selectedIcon: Icon(Icons.storefront),
                        label: 'Shop',
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
}
