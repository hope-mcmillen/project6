import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/logging/app_log.dart';
import 'closet_services.dart';

/// The editable category, color, pattern, formality, and season fields shared
/// by tag review and tag editing.
class ClosetTagForm extends StatefulWidget {
  const ClosetTagForm({
    super.key,
    required this.screen,
    required this.submitLabel,
    required this.onSubmit,
    this.initialTags,
    this.message,
  });

  /// The screen name used in tap logs.
  final String screen;
  final String submitLabel;
  final ValueChanged<ClothingTags> onSubmit;

  /// Starting values. A category we do not use is left for the user to pick.
  final ClothingTags? initialTags;

  /// Shown above the fields, such as why no tags were suggested.
  final String? message;

  @override
  State<ClosetTagForm> createState() => _ClosetTagFormState();
}

class _ClosetTagFormState extends State<ClosetTagForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _color;
  late final TextEditingController _pattern;
  late final TextEditingController _formality;
  late final TextEditingController _season;
  String? _category;

  @override
  void initState() {
    super.initState();
    final tags = widget.initialTags;
    final category = tags?.category.toLowerCase();
    _category = ClothingTags.categories.contains(category) ? category : null;
    _color = TextEditingController(text: tags?.color);
    _pattern = TextEditingController(text: tags?.pattern);
    _formality = TextEditingController(text: tags?.formality);
    _season = TextEditingController(text: tags?.season);
  }

  @override
  void dispose() {
    _color.dispose();
    _pattern.dispose();
    _formality.dispose();
    _season.dispose();
    super.dispose();
  }

  void _submit() {
    AppLog.tap(widget.submitLabel, screen: widget.screen);
    if (!_formKey.currentState!.validate()) {
      AppLog.ui('${widget.screen}: not saved, no category chosen');
      return;
    }
    widget.onSubmit(
      ClothingTags(
        category: _category!,
        color: _color.text.trim(),
        pattern: _pattern.text.trim(),
        formality: _formality.text.trim(),
        season: _season.text.trim(),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(message),
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
                AppLog.tap('Category: $value', screen: widget.screen);
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
          FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
        ],
      ),
    );
  }
}
