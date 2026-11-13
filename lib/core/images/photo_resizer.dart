import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// The longest edge, in pixels, of a photo sent to the AI.
const aiPhotoMaxEdge = 1024;

/// Shrinks a photo so its longest edge is at most [maxEdge] pixels, keeping
/// its proportions, and returns JPEG bytes ready for an AI request.
///
/// Smaller photos are not enlarged. The photo is turned upright using its
/// orientation data first, and re-encoding drops EXIF data such as location.
/// The work runs on a background isolate so the screen does not freeze.
///
/// Throws a [FormatException] if the bytes are not a supported image.
Future<Uint8List> resizePhotoForAi(
  Uint8List bytes, {
  int maxEdge = aiPhotoMaxEdge,
  int quality = 85,
}) {
  if (maxEdge < 1) {
    throw ArgumentError.value(maxEdge, 'maxEdge', 'Must be positive.');
  }
  return compute(_resize, _ResizeJob(bytes, maxEdge, quality));
}

class _ResizeJob {
  const _ResizeJob(this.bytes, this.maxEdge, this.quality);

  final Uint8List bytes;
  final int maxEdge;
  final int quality;
}

Uint8List _resize(_ResizeJob job) {
  var image = img.decodeImage(job.bytes);
  if (image == null) {
    throw const FormatException('Choose a supported photo.');
  }
  image = img.bakeOrientation(image);
  if (image.width > job.maxEdge || image.height > job.maxEdge) {
    final landscape = image.width >= image.height;
    image = img.copyResize(
      image,
      width: landscape ? job.maxEdge : null,
      height: landscape ? null : job.maxEdge,
      interpolation: img.Interpolation.average,
    );
  }
  // The JPEG encoder preserves EXIF unless it is explicitly cleared. Bake the
  // orientation first, then remove GPS, camera data and embedded thumbnails.
  image.exif = img.ExifData();
  return Uint8List.fromList(img.encodeJpg(image, quality: job.quality));
}
