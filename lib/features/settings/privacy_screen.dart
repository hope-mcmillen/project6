import 'package:flutter/material.dart';

import '../../app/privacy_notice.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          PrivacyNotice(),
          Text('You must be 18 or older to use FitCheck AI.'),
        ],
      ),
    );
  }
}
