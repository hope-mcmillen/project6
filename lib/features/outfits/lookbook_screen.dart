import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';

class LookbookScreen extends StatelessWidget {
  const LookbookScreen({super.key});

  static const _sampleOutfits = ['Class outfit', 'Work outfit', 'Night out'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final outfit in _sampleOutfits)
          Card(
            child: ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(outfit),
              subtitle: const Text('Saved sample'),
              onTap: () => showNotBuilt(context, 'FR-8 lookbook'),
            ),
          ),
      ],
    );
  }
}
