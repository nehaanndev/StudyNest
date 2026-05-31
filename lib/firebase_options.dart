import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Replace these placeholder values by running `flutterfire configure`, then
/// copying the generated values into this file if you want to keep manual
/// control inside the repo.
class DefaultFirebaseOptions {
  static const String _placeholder = 'REPLACE_WITH_FLUTTERFIRE';

  // Reports whether the current platform has real Firebase options configured.
  static bool get isConfiguredForCurrentPlatform {
    final options = currentPlatform;
    return options != null && options.apiKey != _placeholder;
  }

  // Returns the Firebase options for the current platform, or null when unset.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  // Returns the optional web client id used for Google sign-in.
  static String? get googleWebClientId {
    if (_googleWebClientId == _placeholder) {
      return null;
    }
    return _googleWebClientId;
  }

  // Returns the optional server client id used for Google sign-in token minting.
  static String? get googleServerClientId {
    if (_googleServerClientId == _placeholder) {
      return null;
    }
    return _googleServerClientId;
  }

  static const String _googleServerClientId = _placeholder;
  static const String _googleWebClientId = _placeholder;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    authDomain: _placeholder,
    storageBucket: _placeholder,
    measurementId: _placeholder,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMtm12L5fDS8trMx5BMC2dsRX9AhP-rKo',
    appId: '1:464139196474:android:c464749e512686a4c9bd03',
    messagingSenderId: '464139196474',
    projectId: 'studynest-e477d',
    databaseURL: 'https://studynest-e477d-default-rtdb.firebaseio.com',
    storageBucket: 'studynest-e477d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB9-EfMvF4crVgkYG7wNDmJll-U3iqaF1k',
    appId: '1:464139196474:ios:9613b16aa90e4796c9bd03',
    messagingSenderId: '464139196474',
    projectId: 'studynest-e477d',
    databaseURL: 'https://studynest-e477d-default-rtdb.firebaseio.com',
    storageBucket: 'studynest-e477d.firebasestorage.app',
    iosBundleId: 'com.example.studynest',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    iosBundleId: 'com.studynest.app',
    storageBucket: _placeholder,
  );
}