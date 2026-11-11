import 'dart:async';

import 'package:fitcheck_ai/app/age_confirmation.dart';
import 'package:fitcheck_ai/app/app.dart';
import 'package:fitcheck_ai/app/app_dependencies.dart';
import 'package:fitcheck_ai/app/connection_status.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/firebase_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A connection the test switches on and off.
class FakeConnectionStatus implements ConnectionStatus {
  FakeConnectionStatus({this.online = true});

  bool online;
  final _changes = StreamController<bool>.broadcast();

  void set(bool value) {
    online = value;
    _changes.add(value);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;
}

/// Saved settings for a phone that has, or has not, passed the welcome screen.
void mockSavedSettings({required bool ageConfirmed}) {
  SharedPreferences.setMockInitialValues({
    if (ageConfirmed) AgeConfirmation.key: true,
  });
}

/// Pumps the whole app on a phone-sized screen with fake services.
Future<void> pumpFitCheckApp(
  WidgetTester tester, {
  BackendServices? services,
  ConnectionStatus? connection,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BackendScope(
      services: services ?? BackendServices.fake(),
      child: FitCheckApp(connection: connection ?? FakeConnectionStatus()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps one screen with the app's services and fake platform services.
Future<void> pumpWithAppServices(
  WidgetTester tester,
  Widget home, {
  BackendServices? services,
  ConnectionStatus? connection,
  Size size = const Size(600, 1600),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BackendScope(
      services: services ?? BackendServices.fake(),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: AppDependencies(
            ageConfirmation: const AgeConfirmation(),
            connection: connection ?? FakeConnectionStatus(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: home,
      ),
    ),
  );
}
