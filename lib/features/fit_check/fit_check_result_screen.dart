import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import '../../core/widgets/photo_placeholder.dart';

class FitCheckResultScreen extends StatelessWidget {
  const FitCheckResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fit Check Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PhotoPlaceholder(height: 200),
          const SizedBox(height: 16),
          Text(
            'Sample verdict: works for class',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.lightbulb),
            title: Text('Sample suggestion one'),
          ),
          const ListTile(
            leading: Icon(Icons.lightbulb),
            title: Text('Sample suggestion two'),
          ),
          const ListTile(
            leading: Icon(Icons.lightbulb),
            title: Text('Sample suggestion three'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showNotBuilt(context, 'F-1 save photo'),
            child: const Text('Save photo'),
          ),
        ],
      ),
    );
  }
}
