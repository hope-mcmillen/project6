import 'package:fitcheck_ai/core/widgets/status_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('LoadingView shows a spinner and its message', (tester) async {
    await pump(tester, const LoadingView(message: 'Suggesting tags...'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Suggesting tags...'), findsOneWidget);
  });

  testWidgets('LoadingView works without a message', (tester) async {
    await pump(tester, const LoadingView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('ErrorRetryView shows the message and calls onRetry', (
    tester,
  ) async {
    var retries = 0;
    await pump(
      tester,
      ErrorRetryView(
        message: 'AI is unavailable. Check your connection and retry.',
        onRetry: () => retries++,
      ),
    );

    expect(
      find.text('AI is unavailable. Check your connection and retry.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('OfflineView explains that only AI needs a connection', (
    tester,
  ) async {
    await pump(tester, const OfflineView());

    expect(find.text(OfflineView.message), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('OfflineView offers Try again when given onRetry', (
    tester,
  ) async {
    var retries = 0;
    await pump(tester, OfflineView(onRetry: () => retries++));

    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
}
