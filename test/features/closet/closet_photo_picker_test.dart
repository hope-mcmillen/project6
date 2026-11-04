import 'dart:io';

import 'package:fitcheck_ai/features/closet/closet_photo_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  late Directory tempDirectory;
  late Directory documents;
  late File pickedFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('closet_photo_test');
    documents = await Directory('${tempDirectory.path}/documents').create();
    pickedFile = File('${tempDirectory.path}/picked.png');
    await pickedFile.writeAsBytes([1, 2, 3, 4]);
  });

  tearDown(() => tempDirectory.delete(recursive: true));

  ClosetPhotoPicker pickerReturning(XFile? file) {
    return ClosetPhotoPicker(
      pickImage: (_) async => file,
      photosDirectory: () async => documents,
    );
  }

  test('saves a copy that survives the original being removed', () async {
    final picker = pickerReturning(XFile(pickedFile.path));

    final savedPath = await picker.pickAndSave(ImageSource.gallery);
    await pickedFile.delete();

    expect(savedPath, startsWith('${documents.path}/closet_photos/'));
    expect(savedPath, endsWith('.png'));
    expect(await File(savedPath!).readAsBytes(), [1, 2, 3, 4]);
  });

  test('gives each saved photo its own file', () async {
    final picker = pickerReturning(XFile(pickedFile.path));

    final first = await picker.pickAndSave(ImageSource.camera);
    final second = await picker.pickAndSave(ImageSource.camera);

    expect(first, isNot(second));
    expect(await File(first!).exists(), isTrue);
    expect(await File(second!).exists(), isTrue);
  });

  test('uses a jpg extension when the picked file has none', () async {
    final noExtension = await pickedFile.copy('${tempDirectory.path}/picked');
    final picker = pickerReturning(XFile(noExtension.path));

    final savedPath = await picker.pickAndSave(ImageSource.camera);

    expect(savedPath, endsWith('.jpg'));
  });

  test('returns null and saves nothing when the user cancels', () async {
    final savedPath = await pickerReturning(null)
        .pickAndSave(ImageSource.camera);

    expect(savedPath, isNull);
    expect(
      await Directory('${documents.path}/closet_photos').exists(),
      isFalse,
    );
  });

  test('lets a denied camera error reach the screen', () {
    final picker = ClosetPhotoPicker(
      pickImage: (_) async =>
          throw PlatformException(code: 'camera_access_denied'),
      photosDirectory: () async => documents,
    );

    expect(
      picker.pickAndSave(ImageSource.camera),
      throwsA(isA<PlatformException>()),
    );
  });
}
