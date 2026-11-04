import 'package:fitcheck_ai/features/closet/add_item_screen.dart';
import 'package:fitcheck_ai/features/closet/closet_photo_picker.dart';
import 'package:fitcheck_ai/features/closet/tag_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class FakeClosetPhotoPicker extends ClosetPhotoPicker {
  FakeClosetPhotoPicker(this.onPick);

  final Future<String?> Function(ImageSource source) onPick;

  @override
  Future<String?> pickAndSave(ImageSource source) => onPick(source);
}

Future<void> openScreen(WidgetTester tester, ClosetPhotoPicker picker) async {
  await tester.pumpWidget(
    MaterialApp(home: AddItemScreen(photoPicker: picker)),
  );
}

void main() {
  const savedPath = '/photos/shirt.jpg';

  testWidgets('camera photo opens tag review with its path', (tester) async {
    late ImageSource usedSource;
    await openScreen(
      tester,
      FakeClosetPhotoPicker((source) async {
        usedSource = source;
        return savedPath;
      }),
    );

    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(usedSource, ImageSource.camera);
    final review = tester.widget<TagReviewScreen>(find.byType(TagReviewScreen));
    expect(review.photoPath, savedPath);
  });

  testWidgets('gallery photo opens tag review with its path', (tester) async {
    late ImageSource usedSource;
    await openScreen(
      tester,
      FakeClosetPhotoPicker((source) async {
        usedSource = source;
        return savedPath;
      }),
    );

    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(usedSource, ImageSource.gallery);
    final review = tester.widget<TagReviewScreen>(find.byType(TagReviewScreen));
    expect(review.photoPath, savedPath);
  });

  testWidgets('cancelling stays on the add item screen', (tester) async {
    await openScreen(tester, FakeClosetPhotoPicker((_) async => null));

    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(find.byType(TagReviewScreen), findsNothing);
    expect(find.text('Take photo'), findsOneWidget);
  });

  testWidgets('denied camera explains itself and gallery still works', (
    tester,
  ) async {
    await openScreen(
      tester,
      FakeClosetPhotoPicker((source) async {
        if (source == ImageSource.camera) {
          throw PlatformException(code: 'camera_access_denied');
        }
        return savedPath;
      }),
    );

    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(find.byType(TagReviewScreen), findsNothing);
    expect(find.textContaining('Could not open the camera'), findsOneWidget);

    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(find.byType(TagReviewScreen), findsOneWidget);
  });

  testWidgets('buttons are disabled while a photo is being picked', (
    tester,
  ) async {
    await openScreen(
      tester,
      FakeClosetPhotoPicker(
        (_) => Future<String?>.delayed(const Duration(seconds: 1)),
      ),
    );

    await tester.tap(find.text('Take photo'));
    await tester.pump();

    ButtonStyleButton buttonWithin(String label) {
      return tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
    }

    expect(buttonWithin('Take photo').onPressed, isNull);
    expect(buttonWithin('Choose from gallery').onPressed, isNull);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(buttonWithin('Take photo').onPressed, isNotNull);
    expect(buttonWithin('Choose from gallery').onPressed, isNotNull);
  });
}
