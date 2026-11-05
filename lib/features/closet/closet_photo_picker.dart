import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

typedef PickImage = Future<XFile?> Function(ImageSource source);
typedef PhotosDirectory = Future<Directory> Function();

/// Lets the user pick a clothing photo and keeps a copy on the phone.
///
/// The picker's own file can live in a temporary folder the system may clear,
/// so the closet always uses its own copy.
class ClosetPhotoPicker {
  ClosetPhotoPicker({PickImage? pickImage, PhotosDirectory? photosDirectory})
    : _pickImage = pickImage ?? _pickWithImagePicker,
      _photosDirectory = photosDirectory ?? getApplicationDocumentsDirectory;

  final PickImage _pickImage;
  final PhotosDirectory _photosDirectory;

  static Future<XFile?> _pickWithImagePicker(ImageSource source) {
    return ImagePicker().pickImage(source: source);
  }

  /// Returns the saved photo's path, or null if the user cancels.
  ///
  /// Throws a [PlatformException] if the picker cannot open, such as when
  /// access is denied.
  Future<String?> pickAndSave(ImageSource source) async {
    final picked = await _pickImage(source);
    if (picked == null) return null;

    final photosDirectory = await _photosDirectory();
    final closetPhotos = Directory('${photosDirectory.path}/closet_photos');
    await closetPhotos.create(recursive: true);

    final id = DateTime.now().microsecondsSinceEpoch;
    final savedPath = '${closetPhotos.path}/$id${_extensionOf(picked.path)}';
    await File(picked.path).copy(savedPath);
    return savedPath;
  }

  static String _extensionOf(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '.jpg' : fileName.substring(dot);
  }
}

/// Removes a saved closet photo. A file that is already gone is not an error.
Future<void> deleteClosetPhoto(String photoPath) async {
  try {
    await File(photoPath).delete();
  } on PathNotFoundException {
    return;
  }
}
