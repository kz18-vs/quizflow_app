import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web; //  Configuration pour le Web (Chrome)
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDvmq7u2feoww2GIKJDZaNwSvLk6bE1PD0",
    appId: "1:636429947040:web:106c2f1ac7ab8e999e39c5",
    messagingSenderId: "636429947040",
    projectId: "quizflow-app-b98ee",
    authDomain: "quizflow-app-b98ee.firebaseapp.com",
    storageBucket: "quizflow-app-b98ee.firebasestorage.app",
  );
}