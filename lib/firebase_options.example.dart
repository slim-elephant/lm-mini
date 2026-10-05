// Example Firebase options so the open-source / stub tree compiles.
// Copy to lib/firebase_options.dart (gitignored) for a real Firebase project:
//
//   cp lib/firebase_options.example.dart lib/firebase_options.dart
//
// CI copies this file automatically when firebase_options.dart is absent.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:0:android:0',
    messagingSenderId: '0',
    projectId: 'lm-mini-oss-stub',
    storageBucket: 'lm-mini-oss-stub.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:0:ios:0',
    messagingSenderId: '0',
    projectId: 'lm-mini-oss-stub',
    storageBucket: 'lm-mini-oss-stub.appspot.com',
    iosBundleId: 'net.neuro9.lmmini',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:0:ios:0',
    messagingSenderId: '0',
    projectId: 'lm-mini-oss-stub',
    storageBucket: 'lm-mini-oss-stub.appspot.com',
    iosBundleId: 'net.neuro9.lmmini',
  );
}
