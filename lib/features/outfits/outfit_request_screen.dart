import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import 'outfit_results_screen.dart';

class OutfitRequestScreen extends StatelessWidget {
  const OutfitRequestScreen({super.key});

  static const _occasions = ['Class', 'Work', 'Going out', 'Interview'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.wb_sunny),
            title: Text('Sample weather: 72°F'),
            subtitle: Text('10% chance of rain'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Occasion', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final occasion in _occasions)
              ChoiceChip(
                label: Text(occasion),
                selected: occasion == 'Class',
                onSelected: (_) => showNotBuilt(context, 'FR-5 occasion'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Optional note',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OutfitResultsScreen()),
            );
          },
          child: const Text('Get outfits'),
        ),
      ],
    );
  }
}
