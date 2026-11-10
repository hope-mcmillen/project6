import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
import 'closet_photo.dart';
import 'closet_services.dart';
import 'closet_tag_form.dart';

/// Changes the tags of an item already in the closet. Pops with the updated
/// item, or with nothing if the user backs out.
class EditTagsScreen extends StatefulWidget {
  const EditTagsScreen({super.key, required this.item, this.repository});

  final ClothingItem item;
  final ClosetRepository? repository;

  @override
  State<EditTagsScreen> createState() => _EditTagsScreenState();
}

class _EditTagsScreenState extends State<EditTagsScreen> {
  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;

  void _save(ClothingTags tags) {
    final updated = widget.item.copyWith(tags: tags);
    AppLog.ui(
      'Edit Tags: updated ${updated.id}; Firestore confirms in the background',
    );
    final messenger = ScaffoldMessenger.of(context);
    // Like adding an item, the change shows right away and Firestore confirms
    // it once the phone is online, so the screen does not wait.
    unawaited(
      _repository.saveItem(updated).catchError((Object _) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not save your changes. Try again.'),
            ),
          );
      }),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Tags updated')));
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Tags')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClosetPhoto(
            photoPath: item.photoPath,
            height: 240,
            fit: BoxFit.contain,
            semanticLabel: 'Photo of ${itemName(item)}',
          ),
          const SizedBox(height: 16),
          ClosetTagForm(
            screen: 'Edit Tags',
            submitLabel: 'Save changes',
            initialTags: item.tags,
            onSubmit: _save,
          ),
        ],
      ),
    );
  }
}
