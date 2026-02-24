// File generated manually for SikaFlow - Firebase multi-platform config
// Project: sikaflow-c8869

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ Config Web - App "SikaFlow Web" (ID: 1:246919869370:web:c3cc3102876ac1e8252383)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApGdz7u5i10Fytoz6hcej63rVTKeH9Ivg',
    appId: '1:246919869370:web:c3cc3102876ac1e8252383',
    messagingSenderId: '246919869370',
    projectId: 'sikaflow-c8869',
    authDomain: 'sikaflow-c8869.firebaseapp.com',
    storageBucket: 'sikaflow-c8869.firebasestorage.app',
    measurementId: 'G-RBJDZRDCWE',
  );

  // ✅ Config Android - depuis google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-YY2qUVN7GadnAYWVkiyqfu3dd7m-_Qo',
    appId: '1:246919869370:android:05d629e08dce5196252383',
    messagingSenderId: '246919869370',
    projectId: 'sikaflow-c8869',
    storageBucket: 'sikaflow-c8869.firebasestorage.app',
  );
}
