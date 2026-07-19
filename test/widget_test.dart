import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/main.dart';

// Runs widget tests for the StudyNest app shell.
void main() {
  testWidgets('First launch starts at welcome and can continue to dashboard', (
    tester,
  ) async {
    // Starts from a fresh in-memory state so the first-use choice is required.
    await tester.pumpWidget(StudyNestApp(appState: StudyNestState.preview()));

    expect(find.text('Continue without an account'), findsOneWidget);

    // Continues as an anonymous user and waits for the dashboard shell.
    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();

    expect(find.text('Current focus goal'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between screens', (tester) async {
    // Builds the app so the bottom navigation can be exercised.
    final state = StudyNestState.preview();
    await state.completeWelcome();
    await tester.pumpWidget(StudyNestApp(appState: state));

    expect(find.text('Current focus goal'), findsOneWidget);
    expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);

    // Selects the Tasks tab and waits for the UI to settle.
    await tester.tap(find.byIcon(Icons.checklist_outlined));
    await tester.pumpAndSettle();

    expect(
      find.text('Turn tiny wins into coins for your shop.'),
      findsOneWidget,
    );
  });

  testWidgets('More destinations retain the shared bottom navigation', (
    tester,
  ) async {
    // Uses a returning-user state to test the persistent navigation shell.
    final state = StudyNestState.preview();
    await state.completeWelcome();
    await tester.pumpWidget(StudyNestApp(appState: state));

    // Opens More and selects Shop from its labeled destination sheet.
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    expect(find.text('Theme shelf'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Returning users reopen their last top-level destination', (
    tester,
  ) async {
    // Saves Habits as the destination a returning user last visited.
    final state = StudyNestState.preview();
    await state.completeWelcome();
    await state.setLastDestination('habits');
    await tester.pumpWidget(StudyNestApp(appState: state));

    expect(find.text('Keep your streak going!'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
