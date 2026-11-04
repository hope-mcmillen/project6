import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';

class StyleProfileScreen extends StatelessWidget {
  const StyleProfileScreen({super.key});

  static const _questions = [
    'What is your style?',
    'Which colors should we avoid?',
    'What occasions do you dress for?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Style Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final question in _questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                decoration: InputDecoration(
                  labelText: question,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          FilledButton(
            onPressed: () => showNotBuilt(context, 'F-5 style profile'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
