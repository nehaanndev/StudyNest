import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studynest/app/study_nest_auth_snapshot.dart';
import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/app/study_nest_storage.dart';
import 'package:studynest/main.dart';
import 'package:studynest/screens/pomodoro_screen.dart';

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
      find.text('Plan your wins. Pomodoro cycles earn coins.'),
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
    expect(find.text('Coin earning'), findsOneWidget);
    expect(find.text('Unlock task coins'), findsOneWidget);
    expect(find.text('Pomodoro boosts'), findsOneWidget);
    expect(find.text('8 coins per completed cycle'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Task editor explains and validates the fifty coin maximum', (
    tester,
  ) async {
    final state = StudyNestState.preview();
    await state.completeWelcome();
    await tester.pumpWidget(StudyNestApp(appState: state));

    await tester.tap(find.byIcon(Icons.checklist_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add New Task'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Max 50'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(2), '51');
    await tester.pump();

    expect(find.text('Enter 1–50 coins.'), findsOneWidget);
    expect(find.text('New task'), findsOneWidget);
  });

  testWidgets('Pomodoro skips mint nothing and exact focus duration awards', (
    tester,
  ) async {
    final state = StudyNestState.preview();
    await state.completeWelcome();
    await tester.pumpWidget(StudyNestApp(appState: state));

    await tester.tap(find.byIcon(Icons.hourglass_empty_rounded));
    await tester.pump();
    final timerScroll = find.descendant(
      of: find.byType(PomodoroScreen),
      matching: find.byType(Scrollable),
    );
    await tester.drag(timerScroll, const Offset(0, -420));
    await tester.pump();
    await tester.tap(find.byTooltip('Skip this phase without earning coins'));
    await tester.pump();
    await tester.tap(find.byTooltip('Skip this phase without earning coins'));
    await tester.pump();
    expect(state.coinBalance, 0);

    await tester.tap(find.byTooltip('Start timer'));
    await tester.pump(const Duration(minutes: 25));

    expect(state.coinBalance, 5);
    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('Unlocking later does not label an unpaid task as claimed', (
    tester,
  ) async {
    final snapshot = emptyStudyNestSnapshot();
    snapshot['tasks'] = [
      {
        'id': 'task.locked-completion',
        'title': 'Finish before unlock',
        'details': '',
        'dueAt': DateTime.now().toIso8601String(),
        'reward': 20,
        'completedAt': null,
        'rewardCollected': false,
        'priority': 'Medium',
      },
    ];
    snapshot['coinLedger'] = [
      {
        'id': 'coins.test-funding',
        'label': 'Test funding',
        'amount': 500,
        'createdAt': DateTime.now().toIso8601String(),
        'sourceId': 'test-funding',
      },
    ];
    final state = await StudyNestState.load(
      storage: InMemoryStudyNestStorage(snapshot: snapshot),
    );
    await state.completeWelcome();
    await state.toggleTask('task.locked-completion');
    await state.setLastDestination('tasks');
    await tester.pumpWidget(StudyNestApp(appState: state));

    expect(find.text('No reward earned'), findsOneWidget);

    await state.buyTaskCoinRewards();
    await tester.pump();
    expect(find.text('No reward earned'), findsOneWidget);
    expect(find.text('Claimed'), findsNothing);
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
