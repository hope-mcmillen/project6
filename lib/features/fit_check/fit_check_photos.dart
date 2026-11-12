import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The folder, inside the app's documents folder, for saved Fit Check photos.
const fitCheckPhotosFolder = 'fit_check_photos';

typedef SaveFitCheckPhoto = Future<String> Function(String photoPath);
typedef DiscardFitCheckPhoto = Future<void> Function(String photoPath);

/// Copies a Fit Check photo into the app's own folder and returns its path.
Future<String> saveFitCheckPhoto(
  String photoPath, {
  Future<Directory> Function() photosDirectory =
      getApplicationDocumentsDirectory,
}) async {
  final root = await photosDirectory();
  final folder = Directory('${root.path}/$fitCheckPhotosFolder');
  await folder.create(recursive: true);
  final id = DateTime.now().microsecondsSinceEpoch;
  final saved = await File(photoPath).copy('${folder.path}/$id.jpg');
  return saved.path;
}

/// Deletes the picker's copy of a photo the user did not save. A file that is
/// already gone is not an error.
Future<void> discardFitCheckPhoto(String photoPath) async {
  try {
    await File(photoPath).delete();
  } on FileSystemException {
    return;
  }
}
