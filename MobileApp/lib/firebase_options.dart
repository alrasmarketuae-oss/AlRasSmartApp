import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase project: alras-market
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for Firebase.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0KQuiP9N1jftf5WRRzR6C2pd9eTc5IGs',
    appId: '1:592516755028:android:79dbb13330e6708fd107c1',
    messagingSenderId: '592516755028',
    projectId: 'alras-market',
    storageBucket: 'alras-market.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYJLypetdW-nz-MiYumG_2RtB8SesO4Ds',
    appId: '1:592516755028:ios:18d02cc40307c7bed107c1',
    messagingSenderId: '592516755028',
    projectId: 'alras-market',
    storageBucket: 'alras-market.firebasestorage.app',
    iosBundleId: 'com.mergespice.alrasmarket',
  );

}