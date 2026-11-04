import 'package:flutter/material.dart';

import '../../core/widgets/photo_placeholder.dart';
import 'tag_review_screen.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  void _openTagReview(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TagReviewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PhotoPlaceholder(icon: Icons.add_a_photo, height: 240),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take photo'),
            onPressed: () => _openTagReview(context),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from gallery'),
            onPressed: () => _openTagReview(context),
          ),
        ],
      ),
    );
  }
}
