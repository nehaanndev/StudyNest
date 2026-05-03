import 'package:flutter/material.dart';

import 'app/study_nest_scope.dart';
import 'app/study_nest_state.dart';
import 'screens/home_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/tasks_screen.dart';

// Starts the StudyNest Flutter application with persisted local state.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = await StudyNestState.load();
  runApp(StudyNestApp(appState: appState));
}

class StudyNestApp extends StatelessWidget {
  const StudyNestApp({super.key, required this.appState});

  final StudyNestState appState;

  // Builds the app root and refreshes Material theming when themes change.
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

  // Creates the state that tracks the selected bottom navigation tab.
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    TasksScreen(),
    NotesScreen(),
    PlannerScreen(),
    ShopScreen(),
  ];

  // Builds the tabbed scaffold and changes screens when a tab is tapped.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: 'Notes'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Planner',
          ),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Shop'),
        ],
      ),
    );
  }
}
