import 'package:flutter/material.dart';

import '../../core/widgets/photo_placeholder.dart';
import 'fit_check_result_screen.dart';

class FitCheckScreen extends StatelessWidget {
  const FitCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PhotoPlaceholder(icon: Icons.camera_alt, height: 280),
        const SizedBox(height: 16),
        const Text('Photograph your outfit and get feedback for the occasion.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Check my fit'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FitCheckResultScreen()),
            );
          },
        ),
      ],
    );
  }
}
