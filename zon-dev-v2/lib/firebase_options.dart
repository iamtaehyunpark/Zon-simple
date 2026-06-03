// Firebase configuration for ZON, derived from ios/Runner/GoogleService-Info.plist
// (Firebase project: zon-nai). These values are not secret — they ship inside
// every client build — so committing them is expected FlutterFire practice.
//
// Only iOS is configured (the app is iOS-first). When Android/web are added,
// run `flutterfire configure` to fill in the other platforms.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase is not configured for web. Run `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform. '
          'Run `flutterfire configure` to add it.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-KgS4tfBGjCajrqEi-XGo4EZcQvf-RJg',
    appId: '1:837180839174:ios:cebe5552cfaeeb46a7ba87',
    messagingSenderId: '837180839174',
    projectId: 'zon-nai',
    storageBucket: 'zon-nai.firebasestorage.app',
    iosBundleId: 'app.getzon.zon',
  );
}
