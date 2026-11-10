import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/ai/ai_service.dart';
import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
import 'closet_photo.dart';
import 'closet_photo_picker.dart';
import 'closet_services.dart';
import 'closet_tag_form.dart';

typedef ReadPhoto = Future<Uint8List> Function(String photoPath);

Future<Uint8List> _readPhotoFile(String photoPath) =>
    File(photoPath).readAsBytes();

class TagReviewScreen extends StatefulWidget {
  const TagReviewScreen({
    super.key,
    required this.photoPath,
    this.repository,
    this.ai,
    this.readPhoto = _readPhotoFile,
    this.deletePhoto = deleteClosetPhoto,
    this.onSaved,
  });

  final String photoPath;
  final ClosetRepository? repository;
  final AiService? ai;
  final ReadPhoto readPhoto;

  /// Removes the copied photo if the user leaves without saving it.
  final DeletePhoto deletePhoto;

  /// Called after saving, once the screen has returned to the first route.
  final VoidCallback? onSaved;

  @override
  State<TagReviewScreen> createState() => _TagReviewScreenState();
}

class _TagReviewScreenState extends State<TagReviewScreen> {
  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;
  late final AiService _ai = widget.ai ?? closetServices(context).ai;

  ClothingTags? _suggested;
  bool _isLoadingTags = true;
  String? _tagFailure;

  /// Set once the photo belongs to a saved item, so leaving keeps it.
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    // Backing out, or any other way of leaving without saving, would otherwise
    // leave the copied photo on the phone with no item pointing to it.
    if (!_saved) unawaited(_discardPhoto('left without saving'));
    super.dispose();
  }

  Future<void> _discardPhoto(String reason) async {
    try {
      await widget.deletePhoto(widget.photoPath);
      AppLog.ui('Review Tags: deleted the unsaved photo ($reason)');
    } on FileSystemException catch (error) {
      AppLog.ui('Review Tags: could not delete the unsaved photo: $error');
    }
  }

  Future<void> _loadTags() async {
    try {
      final photo = await widget.readPhoto(widget.photoPath);
      final tags = await _ai.tagClothing(photo);
      if (!mounted) return;
      final category = tags.category.toLowerCase();
      AppLog.ui(
        ClothingTags.categories.contains(category)
            ? 'Review Tags: filled in the suggested tags'
            : 'Review Tags: suggested category "$category" is not one we '
                  'use, so the user must pick one',
      );
      setState(() {
        _suggested = tags;
        _isLoadingTags = false;
      });
    } on Exception catch (error) {
      AppLog.ui(
        'Review Tags: no suggestions, switching to manual entry ($error)',
      );
      if (!mounted) return;
      setState(() {
        _tagFailure = error is AiServiceException
            ? error.message
            : 'We could not suggest tags for this photo.';
        _isLoadingTags = false;
      });
    }
  }

  void _save(ClothingTags tags) {
    _saved = true;
    final item = ClothingItem(
      id: newClosetId(),
      photoPath: widget.photoPath,
      createdAt: DateTime.now(),
      tags: tags,
    );
    AppLog.ui(
      'Review Tags: added ${item.id} to the closet; Firestore confirms in the '
      'background',
    );
    final messenger = ScaffoldMessenger.of(context);
    final discardPhoto = _discardPhoto;
    // Firestore shows the item right away but may not confirm the write until
    // the phone is back online, so the screen does not wait for it.
    unawaited(
      _repository.saveItem(item).catchError((Object _) {
        // The item never made it into the closet, so its photo goes too.
        discardPhoto('save rejected');
        // Replace the "Added" message so the failure is not missed.
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not save that item. Try again.'),
            ),
          );
      }),
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Added to your closet')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final failure = _tagFailure;
    return Scaffold(
      appBar: AppBar(title: const Text('Review Tags')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClosetPhoto(
            photoPath: widget.photoPath,
            height: 240,
            fit: BoxFit.contain,
            semanticLabel: 'Selected clothing photo',
          ),
          const SizedBox(height: 16),
          if (_isLoadingTags)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Suggesting tags...'),
              ],
            )
          else
            ClosetTagForm(
              screen: 'Review Tags',
              submitLabel: 'Save to closet',
              initialTags: _suggested,
              message: failure == null
                  ? null
                  : '$failure Fill in the tags yourself.',
              onSubmit: _save,
            ),
        ],
      ),
    );
  }
}
