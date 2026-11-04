import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import '../../core/widgets/photo_placeholder.dart';

class TagReviewScreen extends StatelessWidget {
  const TagReviewScreen({super.key, this.photoPath});

  /// The saved clothing photo, or null when no photo is available yet.
  final String? photoPath;

  static const _sampleTags = {
    'Category': 'Top',
    'Color': 'Blue',
    'Pattern': 'Solid',
    'Formality': 'Casual',
    'Season': 'All year',
  };

  Widget _buildPhoto() {
    final path = photoPath;
    if (path == null) return const PhotoPlaceholder(height: 160);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        height: 240,
        fit: BoxFit.contain,
        semanticLabel: 'Selected clothing photo',
        errorBuilder: (_, _, _) => const PhotoPlaceholder(height: 160),
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
          _buildPhoto(),
          const SizedBox(height: 16),
          for (final tag in _sampleTags.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                initialValue: tag.value,
                decoration: InputDecoration(
                  labelText: tag.key,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          FilledButton(
            onPressed: () {
              showNotBuilt(context, 'FR-3 save item');
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Save to closet'),
          ),
        ],
      ),
    );
  }
}
