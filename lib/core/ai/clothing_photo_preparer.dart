import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Temporary adapter until M4-12 lands; inject that helper into FirebaseAiService.
/// Decode/resize/re-encode off the UI thread. Re-encoding also strips EXIF data.
Future<Uint8List> prepareClothingPhoto(Uint8List bytes) =>
    compute(_prepare, bytes);

Uint8List _prepare(Uint8List bytes) {
  var image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('Choose a supported clothing photo.');
  }
  image = img.bakeOrientation(image);
  if (image.width > 1024 || image.height > 1024) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? 1024 : null,
      height: image.height > image.width ? 1024 : null,
    );
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}
