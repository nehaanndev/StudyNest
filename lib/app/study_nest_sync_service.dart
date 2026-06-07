import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import 'study_nest_session.dart';

class StudyNestFirebaseSync {
  const StudyNestFirebaseSync._();

  // Reports whether the app has real Firebase options for this platform.
  static bool get isAvailable {
    return DefaultFirebaseOptions.isConfiguredForCurrentPlatform;
  }
}

class StudyNestSyncResolution {
  const StudyNestSyncResolution({required this.session, this.snapshot});

  final StudyNestSessionState session;
  final Map<String, dynamic>? snapshot;
}

abstract class StudyNestSyncService {
  Stream<void> get retryEvents;

  // Starts auth and the first cloud reconciliation against the local snapshot.
  Future<StudyNestSyncResolution> initialize(
    Map<String, dynamic> localSnapshot,
  );

  // Syncs the latest local snapshot to the cloud, resolving conflicts by time.
  Future<StudyNestSyncResolution> sync(Map<String, dynamic> localSnapshot);

  // Upgrades the current anonymous Firebase user into a Google-linked account.
  Future<StudyNestSyncResolution> linkWithGoogle(
    Map<String, dynamic> localSnapshot,
  );

  // Signs in with email and password, merging anonymous data into the account.
  Future<StudyNestSyncResolution> signInWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  );

  // Creates a new account with email and password.
  Future<StudyNestSyncResolution> signUpWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  );

  // Signs out the current user and returns to anonymous state.
  Future<StudyNestSyncResolution> signOut(
    Map<String, dynamic> localSnapshot,
  );

  // Sends a password reset email to the given address.
  Future<String?> sendPasswordResetEmail(String email);

  // Releases any connectivity listeners held by the sync service.
  Future<void> dispose();
}

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

class FirebaseStudyNestSyncService implements StudyNestSyncService {
  FirebaseStudyNestSyncService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _connectivity = connectivity ?? Connectivity(),
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final GoogleSignIn _googleSignIn;
  final StreamController<void> _retryController = StreamController.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _googleInitialized = false;
  bool _firebaseInitialized = false;

  @override
  Stream<void> get retryEvents => _retryController.stream;

  // Boots Firebase, signs in anonymously, and resolves the first cloud snapshot.
  @override
  Future<StudyNestSyncResolution> initialize(
    Map<String, dynamic> localSnapshot,
  ) async {
    final ready = await _ensureFirebaseReady();
    if (!ready) {
      return const DisabledStudyNestSyncService().initialize(localSnapshot);
    }
    await _startConnectivityWatch();
    return _resolveSnapshot(localSnapshot, preferRemoteOnConflict: true);
  }

  // Syncs the newest local state to Firestore and returns the resolved snapshot.
  @override
  Future<StudyNestSyncResolution> sync(
    Map<String, dynamic> localSnapshot,
  ) async {
    final ready = await _ensureFirebaseReady();
    if (!ready) {
      return const DisabledStudyNestSyncService().sync(localSnapshot);
    }
    return _resolveSnapshot(localSnapshot, preferRemoteOnConflict: true);
  }

  // Signs in with email/password, merging anonymous data into the named account.
  @override
  Future<StudyNestSyncResolution> signInWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  ) async {
    final ready = await _ensureFirebaseReady();
    if (!ready) return const DisabledStudyNestSyncService().initialize(localSnapshot);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        final credential = EmailAuthProvider.credential(email: email, password: password);
        try {
          await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
            await _auth.signInWithEmailAndPassword(email: email, password: password);
          } else {
            rethrow;
          }
        }
      } else {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      }
      return _resolveSnapshot(localSnapshot, preferRemoteOnConflict: true);
    } on FirebaseAuthException catch (e) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.error,
          syncStatus: StudyNestSyncStatus.error,
          message: _friendlyAuthError(e),
        ),
      );
    }
  }

  // Creates a new account with email/password, linking in any anonymous data.
  @override
  Future<StudyNestSyncResolution> signUpWithEmail(
    Map<String, dynamic> localSnapshot,
    String email,
    String password,
  ) async {
    final ready = await _ensureFirebaseReady();
    if (!ready) return const DisabledStudyNestSyncService().initialize(localSnapshot);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        final credential = EmailAuthProvider.credential(email: email, password: password);
        try {
          await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            return StudyNestSyncResolution(
              session: _session(
                authStatus: StudyNestAuthStatus.error,
                syncStatus: StudyNestSyncStatus.error,
                message: 'That email already has an account. Try signing in instead.',
              ),
            );
          }
          rethrow;
        }
      } else {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
      }
      return _resolveSnapshot(localSnapshot, preferRemoteOnConflict: false);
    } on FirebaseAuthException catch (e) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.error,
          syncStatus: StudyNestSyncStatus.error,
          message: _friendlyAuthError(e),
        ),
      );
    }
  }

  // Signs out the current user and falls back to anonymous auth.
  @override
  Future<StudyNestSyncResolution> signOut(
    Map<String, dynamic> localSnapshot,
  ) async {
    final ready = await _ensureFirebaseReady();
    if (!ready) return const DisabledStudyNestSyncService().initialize(localSnapshot);
    await _auth.signOut();
    return _resolveSnapshot(localSnapshot, preferRemoteOnConflict: false);
  }

  // Sends a password reset email; returns an error message string or null on success.
  @override
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyAuthError(e);
    }
  }

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

  // Links the current Firebase user with Google credentials and re-syncs data.
  @override
  Future<StudyNestSyncResolution> linkWithGoogle(
    Map<String, dynamic> localSnapshot,
  ) async {
    final ready = await _ensureFirebaseReady();
    if (!ready) {
      return const DisabledStudyNestSyncService().linkWithGoogle(localSnapshot);
    }
    final currentUser = await _ensureUser();
    if (currentUser == null) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.error,
          syncStatus: StudyNestSyncStatus.error,
          message: 'Firebase authentication did not produce a usable user.',
        ),
      );
    }
    try {
      await _ensureGoogleReady();
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return StudyNestSyncResolution(
          session: _session(
            authStatus: StudyNestAuthStatus.error,
            syncStatus: StudyNestSyncStatus.error,
            message: 'Google sign-in did not return an ID token for Firebase.',
          ),
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      if (currentUser.isAnonymous) {
        await currentUser.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }
      return _resolveSnapshot(localSnapshot, preferRemoteOnConflict: true);
    } on FirebaseAuthException catch (error) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.error,
          syncStatus: StudyNestSyncStatus.error,
          message: error.message ?? 'Google linking failed.',
        ),
      );
    } catch (error) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.error,
          syncStatus: StudyNestSyncStatus.error,
          message: 'Google linking failed: $error',
        ),
      );
    }
  }

  // Cancels connectivity listeners owned by the Firebase sync adapter.
  @override
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _retryController.close();
  }

  // Initializes Firebase with the configured options for the current platform.
  Future<bool> _ensureFirebaseReady() async {
    if (_firebaseInitialized) {
      return true;
    }
    final options = DefaultFirebaseOptions.currentPlatform;
    if (!DefaultFirebaseOptions.isConfiguredForCurrentPlatform ||
        options == null) {
      return false;
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    _firebaseInitialized = true;
    return true;
  }

  // Initializes Google Sign-In only once so account linking can be requested.
  Future<void> _ensureGoogleReady() async {
    if (_googleInitialized) {
      return;
    }
    await _googleSignIn.initialize(
      clientId: DefaultFirebaseOptions.googleWebClientId,
      serverClientId: DefaultFirebaseOptions.googleServerClientId,
    );
    _googleInitialized = true;
  }

  // Starts listening for regained connectivity so pending writes can retry.
  Future<void> _startConnectivityWatch() async {
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _retryController.add(null);
      }
    });
  }

  // Ensures a Firebase user exists, defaulting to anonymous auth on first boot.
  Future<User?> _ensureUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  // Resolves remote and local snapshots and writes back the winning state.
  Future<StudyNestSyncResolution> _resolveSnapshot(
    Map<String, dynamic> localSnapshot, {
    required bool preferRemoteOnConflict,
  }) async {
    final currentUser = await _ensureUser();
    if (currentUser == null) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.error,
          syncStatus: StudyNestSyncStatus.error,
          message: 'Firebase authentication failed to create a user.',
        ),
      );
    }
    final online = await _hasConnection();
    if (!online) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.offline,
          hasPendingSync: true,
          user: currentUser,
          message:
              'Offline. Changes are staying local until the connection comes back.',
        ),
      );
    }

    try {
      final remoteSnapshot = await _loadRemoteSnapshot(currentUser.uid);
      final remoteIsNewer = _isRemoteNewer(
        localSnapshot: localSnapshot,
        remoteSnapshot: remoteSnapshot,
      );
      final resolvedSnapshot =
          remoteIsNewer && preferRemoteOnConflict && remoteSnapshot != null
          ? remoteSnapshot
          : localSnapshot;

      if (!remoteIsNewer || remoteSnapshot == null) {
        await _saveRemoteSnapshot(currentUser.uid, resolvedSnapshot);
      }

      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.idle,
          hasPendingSync: false,
          lastSyncedAt: DateTime.now(),
          user: currentUser,
          message: currentUser.isAnonymous
              ? 'Anonymous cloud sync is active.'
              : 'Google-linked cloud sync is active.',
        ),
        snapshot: resolvedSnapshot,
      );
    } on FirebaseException catch (error) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.error,
          hasPendingSync: true,
          user: currentUser,
          message: error.message ?? 'Cloud sync failed.',
        ),
      );
    } catch (error) {
      return StudyNestSyncResolution(
        session: _session(
          authStatus: StudyNestAuthStatus.ready,
          syncStatus: StudyNestSyncStatus.error,
          hasPendingSync: true,
          user: currentUser,
          message: 'Cloud sync failed: $error',
        ),
      );
    }
  }

  // Returns whether the device has any network path worth attempting to use.
  Future<bool> _hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Loads the StudyNest snapshot document for one Firebase user id.
  Future<Map<String, dynamic>?> _loadRemoteSnapshot(String uid) async {
    final doc = await _firestore.doc('users/$uid/studyNest/state').get();
    return doc.data();
  }

  // Saves the complete StudyNest snapshot document for one Firebase user id.
  Future<void> _saveRemoteSnapshot(
    String uid,
    Map<String, dynamic> snapshot,
  ) async {
    await _firestore.doc('users/$uid/studyNest/state').set(snapshot);
  }

  // Compares the two snapshots using the canonical updatedAt field.
  bool _isRemoteNewer({
    required Map<String, dynamic> localSnapshot,
    required Map<String, dynamic>? remoteSnapshot,
  }) {
    if (remoteSnapshot == null) {
      return false;
    }
    final remoteUpdatedAt = DateTime.tryParse(
      remoteSnapshot['updatedAt'] as String? ?? '',
    );
    final localUpdatedAt = DateTime.tryParse(
      localSnapshot['updatedAt'] as String? ?? '',
    );
    if (remoteUpdatedAt == null) {
      return false;
    }
    if (localUpdatedAt == null) {
      return true;
    }
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }

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
