import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/firebase_backend.dart';

void main() {
  testWidgets(
    'waits for startup and makes one shared bundle available to screens',
    (tester) async {
      final pending = Completer<BackendServices>();
      final services = BackendServices.fake();
      await tester.pumpWidget(
        FirebaseBackend(
          load: () => pending.future,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                expect(BackendScope.of(context), same(services));
                return const Text('Connected');
              },
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(services);
      await tester.pumpAndSettle();
      expect(find.text('Connected'), findsOneWidget);
    },
  );
  testWidgets(
    'failed startup retries without exposing raw credentials or errors',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        FirebaseBackend(
          load: () async {
            if (attempts++ == 0) throw StateError('internal detail');
            return BackendServices.fake();
          },
          child: const MaterialApp(home: Text('Connected')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('internal detail'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Connected'), findsOneWidget);
      expect(attempts, 2);
    },
  );
}
