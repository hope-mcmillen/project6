import 'package:flutter/material.dart';

import 'closet_photo.dart';
import 'closet_repository.dart';
import 'clothing_item.dart';
import 'clothing_tagger.dart';

class TagReviewScreen extends StatefulWidget {
  const TagReviewScreen({
    super.key,
    required this.photoPath,
    this.repository,
    this.tagger,
  });

  final String photoPath;
  final ClosetRepository? repository;
  final ClothingTagger? tagger;

  @override
  State<TagReviewScreen> createState() => _TagReviewScreenState();
}

class _TagReviewScreenState extends State<TagReviewScreen> {
  late final ClosetRepository _repository =
      widget.repository ?? defaultClosetRepository;
  late final ClothingTagger _tagger = widget.tagger ?? defaultClothingTagger;

  final _formKey = GlobalKey<FormState>();
  final _color = TextEditingController();
  final _pattern = TextEditingController();
  final _formality = TextEditingController();
  final _season = TextEditingController();

  String? _category;
  bool _isLoadingTags = true;
  bool _tagsFailed = false;
  bool _isSaving = false;

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
      final tags = await _tagger.suggestTags(widget.photoPath);
      if (!mounted) return;
      setState(() {
        _category = clothingCategories.contains(tags.category)
            ? tags.category
            : null;
        _color.text = tags.color;
        _pattern.text = tags.pattern;
        _formality.text = tags.formality;
        _season.text = tags.season;
        _isLoadingTags = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _tagsFailed = true;
        _isLoadingTags = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.addItem(
        ClothingItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          photoPath: widget.photoPath,
          tags: ClothingTags(
            category: _category!,
            color: _color.text.trim(),
            pattern: _pattern.text.trim(),
            formality: _formality.text.trim(),
            season: _season.text.trim(),
          ),
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Added to your closet')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save this item. Try again.')),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (_tagsFailed)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'We could not suggest tags for this photo. '
                'Fill them in yourself.',
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in clothingCategories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Choose a category' : null,
            ),
          ),
          _buildTextField('Color', _color),
          _buildTextField('Pattern', _pattern),
          _buildTextField('Formality', _formality),
          _buildTextField('Season', _season),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Save to closet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Tags')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
