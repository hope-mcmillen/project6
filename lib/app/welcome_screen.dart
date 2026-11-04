import 'package:flutter/material.dart';

import 'app_shell.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.checkroom, size: 72),
            const SizedBox(height: 16),
            Text(
              'FitCheck AI',
              textAlign: .center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Outfits from the clothes you already own.',
              textAlign: .center,
            ),
            const SizedBox(height: 32),
            const Text(
              'Placeholder privacy notice: clothing photos are sent to an AI '
              'service for tagging. You must be 18 or older to use this app.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AppShell()),
                );
              },
              child: const Text('I am 18 or older, continue'),
            ),
          ],
        ),
      ),
    );
  }
}
