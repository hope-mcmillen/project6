import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import 'privacy_screen.dart';
import 'style_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('Style profile'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StyleProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Load sample closet'),
            onTap: () => showNotBuilt(context, 'FR-10 sample closet'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Delete all my data'),
            onTap: () => showNotBuilt(context, 'Delete all my data'),
          ),
        ],
      ),
    );
  }
}
