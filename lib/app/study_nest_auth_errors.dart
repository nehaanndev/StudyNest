part of 'study_nest_sync_service.dart';

// Converts Firebase auth error codes into readable user-facing messages.
String _friendlyAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address isn\'t valid.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email or password is incorrect.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'email-already-in-use':
      return 'That email already has an account.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'network-request-failed':
      return 'No internet connection.';
    default:
      return e.message ?? 'Authentication failed.';
  }
}

extension _FirebaseSessionBuilder on FirebaseStudyNestSyncService {
  // Builds the app-facing auth and sync session snapshot from Firebase state.
  StudyNestSessionState _session({
    required StudyNestAuthStatus authStatus,
    required StudyNestSyncStatus syncStatus,
    bool hasPendingSync = false,
    DateTime? lastSyncedAt,
    User? user,
    String? message,
  }) {
    return StudyNestSessionState(
      authStatus: authStatus,
      syncStatus: syncStatus,
      cloudEnabled: true,
      isAnonymous: user?.isAnonymous ?? true,
      hasPendingSync: hasPendingSync,
      lastSyncedAt: lastSyncedAt,
      userId: user?.uid,
      userEmail: user?.email,
      userDisplayName: user?.displayName,
      message: message,
    );
  }
}
