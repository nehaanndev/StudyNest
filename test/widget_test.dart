import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studynest/app/study_nest_state.dart';
import 'package:studynest/main.dart';

// Runs widget tests for the StudyNest app shell.
void main() {
  testWidgets('Bottom navigation switches between screens', (tester) async {
    // Builds the app so the bottom navigation can be exercised.
    await tester.pumpWidget(StudyNestApp(appState: StudyNestState.preview()));

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

  testWidgets('Shop shows rarity shelves and collection progress', (
    tester,
  ) async {
    // Builds the app and opens the shop through the More sheet.
    await tester.pumpWidget(StudyNestApp(appState: StudyNestState.preview()));

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(find.text('Cozy Cafe collection'), findsOneWidget);
    expect(find.text('Common'), findsWidgets);
    expect(find.text('Legendary'), findsWidgets);
    expect(find.text('Jazz Radio Console'), findsOneWidget);
  });
}
