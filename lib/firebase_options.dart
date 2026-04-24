// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return web; // reuse web config for Windows desktop testing
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyD9yxm0J34Tcx-k3_wRDrDfzGdKh7TX3hU',
    appId:             '1:897005091865:android:b79390bf172030c329be88',
    messagingSenderId: '897005091865',
    projectId:         'expenzeless',
    storageBucket:     'expenzeless.firebasestorage.app',
  );

  // TODO: Replace with your Web app values from Firebase Console
  // Firebase Console → Project Settings → Your apps → Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyD9yxm0J34Tcx-k3_wRDrDfzGdKh7TX3hU',
    appId:             '1:897005091865:android:b79390bf172030c329be88',
    messagingSenderId: '897005091865',
    projectId:         'expenzeless',
    storageBucket:     'expenzeless.firebasestorage.app',
    authDomain:        'expenzeless.firebaseapp.com',
  );
}
