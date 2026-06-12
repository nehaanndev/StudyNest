part of 'study_nest_sync_service.dart';

class DisabledStudyNestSyncService implements StudyNestSyncService {
  const DisabledStudyNestSyncService();

  @override
  Stream<void> get retryEvents => const Stream<void>.empty();

  // Returns a disabled session when Firebase is not configured for the app.
  @override
  Future<StudyNestSyncResolution> initialize(
    Map<String, dynamic> localSnapshot,
  ) async {
    return StudyNestSyncResolution(
      session: StudyNestSessionState.disabled(
        'Firebase is not configured yet. The app is saving locally until you connect a project.',
      ),
    );
  }

  // Returns the disabled session again because no cloud writes are available.
  @override
  Future<StudyNestSyncResolution> sync(
    Map<String, dynamic> localSnapshot,
  ) async {
    return initialize(localSnapshot);
  }

  // Explains that Google linking is unavailable until Firebase is configured.
  @override
  Future<StudyNestSyncResolution> linkWithGoogle(
    Map<String, dynamic> localSnapshot,
  ) async {
    return StudyNestSyncResolution(
      session: StudyNestSessionState.disabled(
        'Connect Firebase first, then Google sign-in can link onto the anonymous cloud account.',
      ),
    );
  }

  @override
  Future<StudyNestSyncResolution> signInWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  ) async => initialize(localSnapshot);

  @override
  Future<StudyNestSyncResolution> signUpWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  ) async => initialize(localSnapshot);

  @override
  Future<StudyNestSyncResolution> signOut(
    Map<String, dynamic> localSnapshot,
  ) async => initialize(localSnapshot);

  @override
  Future<String?> sendPasswordResetEmail(String email) async => null;

  // Leaves nothing to clean up for the disabled local-only sync adapter.
  @override
  Future<void> dispose() async {}
}
