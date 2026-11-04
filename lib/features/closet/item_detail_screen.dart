import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import '../../core/widgets/photo_placeholder.dart';
import 'tag_review_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PhotoPlaceholder(height: 240),
          const SizedBox(height: 8),
          const ListTile(title: Text('Category'), trailing: Text('Sample')),
          const ListTile(title: Text('Color'), trailing: Text('Sample')),
          const ListTile(title: Text('Formality'), trailing: Text('Sample')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TagReviewScreen()),
              );
            },
            child: const Text('Edit tags'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => showNotBuilt(context, 'FR-4 delete item'),
            child: const Text('Delete item'),
          ),
        ],
      ),
    );
  }
}
