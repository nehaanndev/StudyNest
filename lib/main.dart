import 'dart:async';

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
import 'screens/auth/welcome_screen.dart';
import 'widgets/study_nest_navigation.dart';

// Initializes platform services, restores local state, and starts the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final appState = await StudyNestState.load();
  runApp(StudyNestApp(appState: appState));
}

class StudyNestApp extends StatelessWidget {
  const StudyNestApp({super.key, required this.appState});

  final StudyNestState appState;

  // Rebuilds app theme and entry route whenever persisted app state changes.
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
            home: appState.hasCompletedWelcome
                ? const MainScreen()
                : WelcomeScreen(
                    onDismiss: () {
                      unawaited(appState.completeWelcome());
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// Hosts all top-level app destinations so navigation remains visible everywhere.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late StudyNestDestination _destination;

  static const _contentDestinations = [
    StudyNestDestination.dashboard,
    StudyNestDestination.tasks,
    StudyNestDestination.focus,
    StudyNestDestination.planner,
    StudyNestDestination.notes,
    StudyNestDestination.shop,
    StudyNestDestination.habits,
    StudyNestDestination.profile,
  ];

  // Restores the last saved destination when a returning user opens the app.
  @override
  void initState() {
    super.initState();
    _destination = StudyNestDestinationStorage.fromStorageId(
      StudyNestScope.read(context).lastDestinationId,
    );
  }

  // Selects a destination or opens the labeled secondary-navigation sheet.
  void _navigate(StudyNestDestination destination) {
    if (destination == StudyNestDestination.more) {
      unawaited(
        showStudyNestMoreSheet(context, onDestinationSelected: _navigate),
      );
      return;
    }
    if (destination == _destination) {
      return;
    }
    setState(() => _destination = destination);
    unawaited(
      StudyNestScope.read(context).setLastDestination(destination.storageId),
    );
  }

  // Maps the dashboard quick-access buttons to the primary navigation slots.
  void _navigatePrimary(int index) {
    const primaryDestinations = [
      StudyNestDestination.dashboard,
      StudyNestDestination.tasks,
      StudyNestDestination.focus,
      StudyNestDestination.planner,
      StudyNestDestination.notes,
    ];
    if (index >= 0 && index < primaryDestinations.length) {
      _navigate(primaryDestinations[index]);
    }
  }

  // Builds the active destination while retaining every top-level screen state.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _contentDestinations.indexOf(_destination),
        children: [
          HomeScreen(onNavigate: _navigatePrimary),
          const TasksScreen(),
          const PomodoroScreen(),
          const PlannerScreen(),
          const NotesScreen(),
          const ShopScreen(),
          const HabitsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: StudyNestBottomNavigation(
        selectedDestination: _destination,
        onDestinationSelected: _navigate,
      ),
    );
  }
}
