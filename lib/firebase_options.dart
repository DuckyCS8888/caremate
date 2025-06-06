// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCigImYcCw96yeqlDoh_Tw1azA5z2yOgaY',
    appId: '1:758414818221:web:b78a58bf8b7c122479ff24',
    messagingSenderId: '758414818221',
    projectId: 'care-3c01b',
    authDomain: 'care-3c01b.firebaseapp.com',
    storageBucket: 'care-3c01b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLLk3HK3nUfooCvqKK-K_BUw69Df5ulQ8',
    appId: '1:758414818221:android:f9e1164d52d5dc6d79ff24',
    messagingSenderId: '758414818221',
    projectId: 'care-3c01b',
    storageBucket: 'care-3c01b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgu6L85iBDhtGgUUabdZtDG6K5Gsk6xp0',
    appId: '1:758414818221:ios:794acff2a050f12a79ff24',
    messagingSenderId: '758414818221',
    projectId: 'care-3c01b',
    storageBucket: 'care-3c01b.firebasestorage.app',
    iosBundleId: 'com.example.projects',
  );
}

