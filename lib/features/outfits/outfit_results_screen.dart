import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import '../../core/widgets/photo_placeholder.dart';

class OutfitResultsScreen extends StatelessWidget {
  const OutfitResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Outfits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var number = 1; number <= 3; number++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      'Outfit $number',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Expanded(child: PhotoPlaceholder(height: 72)),
                        SizedBox(width: 8),
                        Expanded(child: PhotoPlaceholder(height: 72)),
                        SizedBox(width: 8),
                        Expanded(child: PhotoPlaceholder(height: 72)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Sample reason this outfit suits the occasion.'),
                    Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Save',
                          icon: const Icon(Icons.bookmark_add),
                          onPressed: () =>
                              showNotBuilt(context, 'FR-8 save outfit'),
                        ),
                        IconButton(
                          tooltip: 'Swap a piece',
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: () =>
                              showNotBuilt(context, 'F-2 swap a piece'),
                        ),
                        IconButton(
                          tooltip: 'Good outfit',
                          icon: const Icon(Icons.thumb_up),
                          onPressed: () => showNotBuilt(context, 'F-3 rating'),
                        ),
                        IconButton(
                          tooltip: 'Bad outfit',
                          icon: const Icon(Icons.thumb_down),
                          onPressed: () => showNotBuilt(context, 'F-3 rating'),
                        ),
                        IconButton(
                          tooltip: 'Wear today',
                          icon: const Icon(Icons.today),
                          onPressed: () =>
                              showNotBuilt(context, 'F-4 wear log'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
