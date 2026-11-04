import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import '../../core/widgets/photo_placeholder.dart';

class TagReviewScreen extends StatelessWidget {
  const TagReviewScreen({super.key});

  static const _sampleTags = {
    'Category': 'Top',
    'Color': 'Blue',
    'Pattern': 'Solid',
    'Formality': 'Casual',
    'Season': 'All year',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Tags')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PhotoPlaceholder(height: 160),
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
