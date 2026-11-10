import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/data/firebase_backend.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const app = FitCheckApp();
  runApp(
    DefaultFirebaseOptions.isConfiguredForCurrentPlatform
        ? const FirebaseBackend(child: app)
        : app,
  );
}