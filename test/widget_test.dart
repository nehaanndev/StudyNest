import 'package:flutter_test/flutter_test.dart';

import 'package:studynest/main.dart';

// Runs widget tests for the StudyNest app shell.
void main() {
  testWidgets('Bottom navigation switches between screens', (tester) async {
    // Builds the app so the bottom navigation can be exercised.
    await tester.pumpWidget(const StudyNestApp());

    expect(find.text('🏠 Home'), findsOneWidget);
    expect(find.text('✅ Tasks'), findsNothing);

    // Selects the Tasks tab and waits for the UI to settle.
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('🏠 Home'), findsNothing);
    expect(find.text('✅ Tasks'), findsOneWidget);
  });
}
