import 'dart:typed_data';

import '../images/photo_resizer.dart';

/// Resizes a clothing photo to 1024 px on the long edge and re-encodes it as
/// JPEG off the UI thread, using Member 4's shared helper (M4-12).
/// Re-encoding also strips EXIF data.
Future<Uint8List> prepareClothingPhoto(Uint8List bytes) =>
    resizePhotoForAi(bytes);
