enum StudyNestAuthStatus { disabled, signingIn, ready, error }

enum StudyNestSyncStatus { disabled, idle, syncing, offline, error }

class StudyNestSessionState {
  const StudyNestSessionState({
    required this.authStatus,
    required this.syncStatus,
    required this.cloudEnabled,
    required this.isAnonymous,
    required this.hasPendingSync,
    this.lastSyncedAt,
    this.userId,
    this.userEmail,
    this.userDisplayName,
    this.message,
  });

  final StudyNestAuthStatus authStatus;
  final StudyNestSyncStatus syncStatus;
  final bool cloudEnabled;
  final bool isAnonymous;
  final bool hasPendingSync;
  final DateTime? lastSyncedAt;
  final String? userId;
  final String? userEmail;
  final String? userDisplayName;
  final String? message;

  // Returns the default session used before Firebase is configured.
  factory StudyNestSessionState.disabled([String? message]) {
    return StudyNestSessionState(
      authStatus: StudyNestAuthStatus.disabled,
      syncStatus: StudyNestSyncStatus.disabled,
      cloudEnabled: false,
      isAnonymous: true,
      hasPendingSync: false,
      message: message,
    );
  }

  // Reports whether the current user has upgraded beyond anonymous auth.
  bool get hasLinkedLogin {
    return cloudEnabled &&
        authStatus == StudyNestAuthStatus.ready &&
        !isAnonymous;
  }

  // Creates a copy of the session while replacing only the provided fields.
  StudyNestSessionState copyWith({
    StudyNestAuthStatus? authStatus,
    StudyNestSyncStatus? syncStatus,
    bool? cloudEnabled,
    bool? isAnonymous,
    bool? hasPendingSync,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    String? userId,
    bool clearUserId = false,
    String? userEmail,
    bool clearUserEmail = false,
    String? userDisplayName,
    bool clearUserDisplayName = false,
    String? message,
    bool clearMessage = false,
  }) {
    return StudyNestSessionState(
      authStatus: authStatus ?? this.authStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      cloudEnabled: cloudEnabled ?? this.cloudEnabled,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      userId: clearUserId ? null : userId ?? this.userId,
      userEmail: clearUserEmail ? null : userEmail ?? this.userEmail,
      userDisplayName: clearUserDisplayName
          ? null
          : userDisplayName ?? this.userDisplayName,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudyNestSessionState &&
        other.authStatus == authStatus &&
        other.syncStatus == syncStatus &&
        other.cloudEnabled == cloudEnabled &&
        other.isAnonymous == isAnonymous &&
        other.hasPendingSync == hasPendingSync &&
        other.lastSyncedAt == lastSyncedAt &&
        other.userId == userId &&
        other.userEmail == userEmail &&
        other.userDisplayName == userDisplayName &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(
      authStatus,
      syncStatus,
      cloudEnabled,
      isAnonymous,
      hasPendingSync,
      lastSyncedAt,
      userId,
      userEmail,
      userDisplayName,
      message,
    );
  }
}
