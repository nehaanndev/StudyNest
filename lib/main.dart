import 'package:flutter/material.dart';

// Starts the StudyNest Flutter application.
void main() {
  runApp(const StudyNestApp());
}

class StudyNestApp extends StatelessWidget {
  const StudyNestApp({super.key});

  // Builds the app shell with the global theme and starting screen.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainScreen(),
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

  final screens = [
    const HomeScreen(),
    const TasksScreen(),
    const NotesScreen(),
    const CalendarScreen(),
    const ShopScreen(),
  ];

  // Builds the tabbed scaffold and changes screens when a tab is tapped.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Calendar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Shop"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Builds the home placeholder screen.
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("🏠 Home"));
  }
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  // Builds the tasks placeholder screen.
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("✅ Tasks"));
  }
}

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  // Builds the notes placeholder screen.
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("📝 Notes"));
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  // Builds the calendar placeholder screen.
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("📅 Calendar"));
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  // Builds the shop placeholder screen.
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("🛒 Shop"));
  }
}
