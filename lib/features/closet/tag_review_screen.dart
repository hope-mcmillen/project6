import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/ai/ai_service.dart';
import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
import 'closet_photo.dart';
import 'closet_services.dart';

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
    this.onSaved,
  });

  final String photoPath;
  final ClosetRepository? repository;
  final AiService? ai;
  final ReadPhoto readPhoto;

  /// Called after saving, once the screen has returned to the first route.
  final VoidCallback? onSaved;

  @override
  State<TagReviewScreen> createState() => _TagReviewScreenState();
}

class _TagReviewScreenState extends State<TagReviewScreen> {
  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;
  late final AiService _ai = widget.ai ?? closetServices(context).ai;

  final _formKey = GlobalKey<FormState>();
  final _color = TextEditingController();
  final _pattern = TextEditingController();
  final _formality = TextEditingController();
  final _season = TextEditingController();

  String? _category;
  bool _isLoadingTags = true;
  String? _tagFailure;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _color.dispose();
    _pattern.dispose();
    _formality.dispose();
    _season.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final photo = await widget.readPhoto(widget.photoPath);
      final tags = await _ai.tagClothing(photo);
      if (!mounted) return;
      final category = tags.category.toLowerCase();
      final known = ClothingTags.categories.contains(category);
      AppLog.ui(
        known
            ? 'Review Tags: filled in the suggested tags'
            : 'Review Tags: suggested category "$category" is not one we '
                  'use, so the user must pick one',
      );
      setState(() {
        _category = known ? category : null;
        _color.text = tags.color;
        _pattern.text = tags.pattern;
        _formality.text = tags.formality;
        _season.text = tags.season;
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

  void _save() {
    AppLog.tap('Save to closet', screen: 'Review Tags');
    if (!_formKey.currentState!.validate()) {
      AppLog.ui('Review Tags: not saved, no category chosen');
      return;
    }
    final item = ClothingItem(
      id: newClosetId(),
      photoPath: widget.photoPath,
      createdAt: DateTime.now(),
      tags: ClothingTags(
        category: _category!,
        color: _color.text.trim(),
        pattern: _pattern.text.trim(),
        formality: _formality.text.trim(),
        season: _season.text.trim(),
      ),
    );
    AppLog.ui(
      'Review Tags: added ${item.id} to the closet; Firestore confirms in the '
      'background',
    );
    final messenger = ScaffoldMessenger.of(context);
    // Firestore shows the item right away but may not confirm the write until
    // the phone is back online, so the screen does not wait for it.
    unawaited(
      _repository.saveItem(item).catchError((Object _) {
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildForm() {
    final failure = _tagFailure;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('$failure Fill in the tags yourself.'),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in ClothingTags.categories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(categoryLabel(category)),
                  ),
              ],
              onChanged: (value) {
                AppLog.tap('Category: $value', screen: 'Review Tags');
                setState(() => _category = value);
              },
              validator: (value) => value == null ? 'Choose a category' : null,
            ),
          ),
          _buildTextField('Color', _color),
          _buildTextField('Pattern', _pattern),
          _buildTextField('Formality', _formality),
          _buildTextField('Season', _season),
          const SizedBox(height: 4),
          FilledButton(onPressed: _save, child: const Text('Save to closet')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _buildForm(),
        ],
      ),
    );
  }
}
