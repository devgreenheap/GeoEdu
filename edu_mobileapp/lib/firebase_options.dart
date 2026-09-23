import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // ignore: missing_enum_constant_in_switch
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDMEr7eOZFc2U583ap8cQFueUqzby6VCcQ",
    projectId: "geoedu-da854",
    storageBucket: "geoedu-da854.firebasestorage.app",
    messagingSenderId: "20453271326",
    appId: "1:20453271326:android:533ce2288ea40766e80b0f",
    // ✅ for com.geoedu.app
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDMEr7eOZFc2U583ap8cQFueUqzby6VCcQ",
    appId: "1:20453271326:android:533ce2288ea40766e80b0f",
    messagingSenderId: "20453271326",
    projectId: "geoedu-da854",
    storageBucket: "geoedu-da854.firebasestorage.app",
    iosBundleId: 'com.geoedu.app',
  );
}
