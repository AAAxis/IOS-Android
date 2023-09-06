// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
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
    apiKey: 'AIzaSyASwq11lvLT6YfaGwp7W_dCBICDzVsBbSM',
    appId: '1:868698601721:web:22468b4e21b05b98854a28',
    messagingSenderId: '868698601721',
    projectId: 'bankapp-9798a',
    authDomain: 'bankapp-9798a.firebaseapp.com',
    storageBucket: 'bankapp-9798a.appspot.com',
    measurementId: 'G-KLCELQKK2E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9EIryPjDqw_367UYyLor3z2eFxjsAOYA',
    appId: '1:868698601721:android:22c8da25d19db544854a28',
    messagingSenderId: '868698601721',
    projectId: 'bankapp-9798a',
    storageBucket: 'bankapp-9798a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA80Zdxm2zI06IT4B3ESuTzgNdgedhPgOo',
    appId: '1:868698601721:ios:ebe3a2e4404a741b854a28',
    messagingSenderId: '868698601721',
    projectId: 'bankapp-9798a',
    storageBucket: 'bankapp-9798a.appspot.com',
    androidClientId: '868698601721-ljo16r33pv9hasdcup4h0t2lig9hrv91.apps.googleusercontent.com',
    iosClientId: '868698601721-cirhsmene2313dm3q8668l4pi0gdsdlm.apps.googleusercontent.com',
    iosBundleId: 'com.wheels.orderapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA80Zdxm2zI06IT4B3ESuTzgNdgedhPgOo',
    appId: '1:868698601721:ios:3f631c48df6ec973854a28',
    messagingSenderId: '868698601721',
    projectId: 'bankapp-9798a',
    storageBucket: 'bankapp-9798a.appspot.com',
    androidClientId: '868698601721-ljo16r33pv9hasdcup4h0t2lig9hrv91.apps.googleusercontent.com',
    iosClientId: '868698601721-u80op74015o6bg5h1ecelmkqjjin6nnm.apps.googleusercontent.com',
    iosBundleId: 'com.wheels.orderApp.RunnerTests',
  );
}
