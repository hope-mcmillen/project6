import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/data/firebase_backend.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseBackend(child: FitCheckApp()));
}
