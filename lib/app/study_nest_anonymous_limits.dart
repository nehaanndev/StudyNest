import 'study_nest_session.dart';

class StudyNestAnonymousLimits {
  const StudyNestAnonymousLimits._();

  static const int maxTasks = 20;
  static const int maxNotes = 10;
  static const int maxEvents = 15;
  static const int maxDecorPurchases = 3;

  // Reports whether anonymous limits should be enforced for the active session.
  static bool shouldEnforce(StudyNestSessionState session) {
    return session.cloudEnabled &&
        session.authStatus == StudyNestAuthStatus.ready &&
        session.isAnonymous;
  }

  // Returns the note-cap message shown when the anonymous quota is exhausted.
  static String notesMessage() {
    return 'Anonymous accounts can save up to $maxNotes notes. Link Google to keep unlimited synced notes.';
  }

  // Returns the task-cap message shown when the anonymous quota is exhausted.
  static String tasksMessage() {
    return 'Anonymous accounts can keep up to $maxTasks tasks. Link Google to remove the task cap.';
  }

  // Returns the planner-cap message shown when the anonymous quota is exhausted.
  static String eventsMessage() {
    return 'Anonymous accounts can keep up to $maxEvents planner blocks. Link Google to remove the planner cap.';
  }

  // Returns the decor-cap message shown when the anonymous quota is exhausted.
  static String decorMessage() {
    return 'Anonymous accounts can unlock up to $maxDecorPurchases decor purchases. Link Google to unlock more decor.';
  }

  // Returns the session-goal message shown after the anonymous custom goal is used.
  static String sessionGoalMessage() {
    return 'Anonymous accounts can save one custom focus goal. Link Google to keep editing it freely.';
  }
}
