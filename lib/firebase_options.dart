// Real Firebase Options for DO you Parental Control application (Project: do-you-63ac5)

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbMpM7Gxex_-45b0uI6mfY0MvOv9jE5Oo',
    appId: '1:648842993184:web:84a4d3e20b7e56bc0e2645',
    messagingSenderId: '648842993184',
    projectId: 'do-you-63ac5',
    authDomain: 'do-you-63ac5.firebaseapp.com',
    storageBucket: 'do-you-63ac5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbMpM7Gxex_-45b0uI6mfY0MvOv9jE5Oo',
    appId: '1:648842993184:android:84a4d3e20b7e56bc0e2645',
    messagingSenderId: '648842993184',
    projectId: 'do-you-63ac5',
    storageBucket: 'do-you-63ac5.firebasestorage.app',
    databaseURL: 'https://do-you-63ac5-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbMpM7Gxex_-45b0uI6mfY0MvOv9jE5Oo',
    appId: '1:648842993184:ios:84a4d3e20b7e56bc0e2645',
    messagingSenderId: '648842993184',
    projectId: 'do-you-63ac5',
    storageBucket: 'do-you-63ac5.firebasestorage.app',
    iosBundleId: 'com.doyou.parentalcontrol',
  );
}
