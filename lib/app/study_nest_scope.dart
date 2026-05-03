import 'package:flutter/widgets.dart';

import 'study_nest_state.dart';

class StudyNestScope extends InheritedNotifier<StudyNestState> {
  const StudyNestScope({
    super.key,
    required StudyNestState state,
    required super.child,
  }) : super(notifier: state);

  // Returns the nearest shared StudyNest state and rebuilds when it changes.
  static StudyNestState watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StudyNestScope>();
    assert(scope != null, 'StudyNestScope is missing above this context.');
    return scope!.notifier!;
  }

  // Returns the nearest shared StudyNest state without subscribing to updates.
  static StudyNestState read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<StudyNestScope>();
    final scope = element?.widget as StudyNestScope?;
    assert(scope != null, 'StudyNestScope is missing above this context.');
    return scope!.notifier!;
  }
}
