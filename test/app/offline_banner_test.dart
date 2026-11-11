import 'package:fitcheck_ai/core/widgets/status_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test_helpers.dart';

void main() {
  setUp(() => mockSavedSettings(ageConfirmed: true));

  testWidgets('no banner while online', (tester) async {
    await pumpFitCheckApp(tester, connection: FakeConnectionStatus());

    expect(find.text(OfflineView.message), findsNothing);
  });

  testWidgets('the banner appears offline and goes when back online', (
    tester,
  ) async {
    final connection = FakeConnectionStatus();
    await pumpFitCheckApp(tester, connection: connection);

    connection.set(false);
    await tester.pumpAndSettle();
    expect(find.text(OfflineView.message), findsOneWidget);

    connection.set(true);
    await tester.pumpAndSettle();
    expect(find.text(OfflineView.message), findsNothing);
  });

  testWidgets('the banner shows at launch when already offline', (
    tester,
  ) async {
    await pumpFitCheckApp(
      tester,
      connection: FakeConnectionStatus(online: false),
    );

    expect(find.text(OfflineView.message), findsOneWidget);
  });

  testWidgets('the banner stays across tabs', (tester) async {
    final connection = FakeConnectionStatus(online: false);
    await pumpFitCheckApp(tester, connection: connection);

    for (final tab in ['Wardrobe', 'Add item', 'Fit Check']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pumpAndSettle();
      expect(find.text(OfflineView.message), findsOneWidget, reason: tab);
    }
  });
}
