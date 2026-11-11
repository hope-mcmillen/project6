import 'package:flutter/material.dart';

import '../core/logging/app_log.dart';
import 'age_confirmation.dart';
import 'app_dependencies.dart';
import 'connection_status.dart';
import 'startup_gate.dart';

const plum = Color(0xFF7043D4);
const ink = Color(0xFF292334);

class FitCheckApp extends StatelessWidget {
  const FitCheckApp({
    super.key,
    this.ageConfirmation = const AgeConfirmation(),
    this.connection = const DeviceConnectionStatus(),
  });

  final AgeConfirmation ageConfirmation;
  final ConnectionStatus connection;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fitcheck AI',
    debugShowCheckedModeBanner: false,
    navigatorObservers: [AppNavigatorObserver()],
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAF8FC),
      colorScheme: ColorScheme.fromSeed(seedColor: plum, primary: plum),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    // Above the navigator, so every route can reach these.
    builder: (context, child) => AppDependencies(
      ageConfirmation: ageConfirmation,
      connection: connection,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const StartupGate(),
  );
}
