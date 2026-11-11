import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../app/age_confirmation.dart';
import '../../core/data/backend_services.dart';
import '../../core/data/models.dart';
import '../../core/logging/app_log.dart';
import '../fit_check/fit_check_photos.dart';

/// Deletes everything the app stored for this user: Firestore data, photos
/// saved on the phone, and the 18+ confirmation.
class MyDataDeleter {
  MyDataDeleter({
    required this.services,
    this.ageConfirmation = const AgeConfirmation(),
    Future<Directory> Function()? photosDirectory,
    this.firestoreWait = const Duration(seconds: 10),
  }) : _photosDirectory = photosDirectory ?? getApplicationDocumentsDirectory;

  /// Folders inside the documents folder that hold this app's photos.
  static const photoFolders = ['closet_photos', fitCheckPhotosFolder];

  final BackendServices services;
  final AgeConfirmation ageConfirmation;
  final Future<Directory> Function() _photosDirectory;

  /// How long to wait for Firestore to confirm. Offline deletes are queued
  /// and finish when the phone reconnects, so the app does not wait forever.
  final Duration firestoreWait;

  Future<void> deleteAll() async {
    final items = await services.closet.getItems();
    final outfits = await services.outfits.watchOutfits().first;
    AppLog.data(
      'Deleting all data: ${items.length} items, ${outfits.length} outfits',
    );

    await _waitForFirestore([
      for (final item in items) services.closet.deleteItem(item.id),
      for (final outfit in outfits) services.outfits.deleteOutfit(outfit.id),
      services.profile.saveProfile(StyleProfile()),
    ]);

    for (final item in items) {
      await _deleteFile(item.photoPath);
    }
    final root = await _photosDirectory();
    for (final folder in photoFolders) {
      await _deleteFolder(Directory('${root.path}/$folder'));
    }

    await ageConfirmation.clear();
    AppLog.data('All data deleted');
  }

  /// Waits for Firestore to confirm, up to [firestoreWait]. A rejected write
  /// is rethrown; one still waiting for a connection is left queued.
  Future<void> _waitForFirestore(List<Future<void>> writes) async {
    Object? failure;
    final settled = [
      for (final write in writes)
        write.then<void>(
          (_) {},
          onError: (Object error) {
            failure ??= error;
          },
        ),
    ];
    await Future.wait(settled).timeout(
      firestoreWait,
      onTimeout: () {
        AppLog.data('Offline: deletes will finish when the phone reconnects');
        return <void>[];
      },
    );
    final error = failure;
    if (error != null) throw error;
  }

  static Future<void> _deleteFile(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      return;
    }
  }

  static Future<void> _deleteFolder(Directory folder) async {
    try {
      await folder.delete(recursive: true);
    } on FileSystemException {
      return;
    }
  }
}
