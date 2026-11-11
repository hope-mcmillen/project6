import 'dart:typed_data';

import 'package:fitcheck_ai/core/images/photo_resizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List samplePng(int width, int height) =>
    Uint8List.fromList(img.encodePng(img.Image(width: width, height: height)));

img.Image decoded(Uint8List bytes) => img.decodeJpg(bytes)!;

void main() {
  test('a wide photo comes back 1024 px wide', () async {
    final result = decoded(await resizePhotoForAi(samplePng(2048, 1024)));

    expect(result.width, 1024);
    expect(result.height, 512);
  });

  test('a tall photo comes back 1024 px tall', () async {
    final result = decoded(await resizePhotoForAi(samplePng(1000, 3000)));

    expect(result.height, 1024);
    expect(result.width, closeTo(341, 1));
  });

  test('a small photo is not enlarged', () async {
    final result = decoded(await resizePhotoForAi(samplePng(300, 200)));

    expect(result.width, 300);
    expect(result.height, 200);
  });

  test('the result is JPEG', () async {
    final bytes = await resizePhotoForAi(samplePng(40, 40));

    expect(img.findFormatForData(bytes), img.ImageFormat.jpg);
  });

  test('a custom max edge is respected', () async {
    final result = decoded(
      await resizePhotoForAi(samplePng(400, 100), maxEdge: 200),
    );

    expect(result.width, 200);
    expect(result.height, 50);
  });

  test('bytes that are not an image throw a FormatException', () {
    expect(
      resizePhotoForAi(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<FormatException>()),
    );
  });
}
