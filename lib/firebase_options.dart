import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Real Android client configuration verified in the Firebase/Cloud consoles.
/// Firebase client keys identify the app; Security Rules and App Check authorize it.
/// No Gemini Developer API secret belongs here.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase is configured for Android. Register other platforms before using them.',
    );
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCeMmz_5BBKo-FEKvLXnAmAFTn1sfqan2Y',
    appId: '1:376143188914:android:b50071b9e266e4163f0aab',
    messagingSenderId: '376143188914',
    projectId: 'fitcheck-ai-258e1',
  );
}
