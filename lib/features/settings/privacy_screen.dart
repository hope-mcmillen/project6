import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Placeholder privacy notice. Final wording goes here.'),
      ),
    );
  }
}
