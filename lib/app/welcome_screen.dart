import 'package:flutter/material.dart';

import 'privacy_notice.dart';

/// First-launch screen: the privacy notice and the 18+ confirmation.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onConfirmed});

  /// Saves the confirmation. The screen shows an error if it throws.
  final Future<void> Function() onConfirmed;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      await widget.onConfirmed();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.checkroom,
              size: 72,
              color: theme.colorScheme.primary,
              semanticLabel: 'FitCheck AI logo',
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'FitCheck AI',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Outfits from the clothes you already own.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Semantics(
              header: true,
              child: Text(
                'Before you start',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            const PrivacyNotice(),
            const SizedBox(height: 8),
            const Text(
              'You must be 18 or older to use FitCheck AI.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _confirm,
              child: const Text('I am 18 or older, continue'),
            ),
          ],
        ),
      ),
    );
  }
}
