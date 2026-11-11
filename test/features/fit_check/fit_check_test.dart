import 'dart:typed_data';

import 'package:fitcheck_ai/features/fit_check/fit_check_result_screen.dart';
import 'package:fitcheck_ai/features/fit_check/fit_check_screen.dart';
import 'package:fitcheck_ai/features/fit_check/fit_check_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

const photoPath = '/picked/outfit.jpg';

class PhotoLog {
  final saved = <String>[];
  final discarded = <String>[];

  Future<String> save(String path) async {
    saved.add(path);
    return '/saved/outfit.jpg';
  }

  Future<void> discard(String path) async => discarded.add(path);
}

Future<void> pumpResult(
  WidgetTester tester,
  FitCheckService service,
  PhotoLog photos,
) async {
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: FitCheckResultScreen(
        photoPath: photoPath,
        occasion: 'Work',
        service: service,
        readPhoto: (_) async => Uint8List.fromList([1, 2, 3]),
        preparePhoto: (bytes) async => bytes,
        savePhoto: photos.save,
        discardPhoto: photos.discard,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows the verdict and up to 3 suggestions', (tester) async {
    final service = FakeFitCheckService();
    await pumpResult(tester, service, PhotoLog());

    expect(find.text('Works well for work.'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsNWidgets(3));
    expect(service.lastRequest?.occasion, 'Work');
    expect(service.lastRequest?.photo, [1, 2, 3]);
  });

  testWidgets('a failure shows Retry, and retrying shows feedback', (
    tester,
  ) async {
    final service = FakeFitCheckService(failuresBeforeSuccess: 1);
    await pumpResult(tester, service, PhotoLog());

    expect(
      find.text('AI is unavailable. Check your connection and retry.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(service.calls, 2);
    expect(find.text('Works well for work.'), findsOneWidget);
  });

  testWidgets('before M3-09 lands, it says feedback is not connected', (
    tester,
  ) async {
    await pumpResult(tester, const PendingFitCheckService(), PhotoLog());

    expect(find.textContaining('not connected yet'), findsOneWidget);
  });

  testWidgets('an unsaved photo is discarded when the screen closes', (
    tester,
  ) async {
    final photos = PhotoLog();
    await pumpResult(tester, FakeFitCheckService(), photos);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(photos.saved, isEmpty);
    expect(photos.discarded, [photoPath]);
  });

  testWidgets('Save photo keeps a copy before the picked file is removed', (
    tester,
  ) async {
    final photos = PhotoLog();
    await pumpResult(tester, FakeFitCheckService(), photos);

    await tester.tap(find.text('Save photo'));
    await tester.pump();
    expect(find.text('Photo saved'), findsWidgets);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(photos.saved, [photoPath]);
    expect(photos.discarded, [photoPath]);
  });

  testWidgets('the Fit Check tab sends the chosen occasion', (tester) async {
    final service = FakeFitCheckService();
    ImageSource? usedSource;
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FitCheckScreen(
            service: service,
            pickPhoto: (source) async {
              usedSource = source;
              return XFile(photoPath);
            },
          ),
        ),
      ),
    );

    expect(find.text(FitCheckScreen.photoRule), findsOneWidget);
    await tester.tap(find.text('Interview'));
    await tester.pump();
    await tester.tap(find.text('Choose from gallery'));
    // The result screen keeps a spinner running, so wait for the page
    // transition rather than for every animation to stop.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(usedSource, ImageSource.gallery);
    final result = tester.widget<FitCheckResultScreen>(
      find.byType(FitCheckResultScreen),
    );
    expect(result.occasion, 'Interview');
    expect(result.photoPath, photoPath);
  });

  testWidgets('a cancelled photo stays on the Fit Check tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FitCheckScreen(pickPhoto: (_) async => null)),
      ),
    );

    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(find.byType(FitCheckResultScreen), findsNothing);
  });
}
