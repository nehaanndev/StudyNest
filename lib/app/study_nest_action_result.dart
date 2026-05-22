class StudyNestActionResult {
  const StudyNestActionResult({
    required this.applied,
    required this.message,
    this.requiresLoginUpgrade = false,
  });

  final bool applied;
  final String message;
  final bool requiresLoginUpgrade;

  // Builds a success result for app mutations that changed state.
  factory StudyNestActionResult.success(String message) {
    return StudyNestActionResult(applied: true, message: message);
  }

  // Builds a blocked result for mutations that were refused.
  factory StudyNestActionResult.blocked(
    String message, {
    bool requiresLoginUpgrade = false,
  }) {
    return StudyNestActionResult(
      applied: false,
      message: message,
      requiresLoginUpgrade: requiresLoginUpgrade,
    );
  }
}
