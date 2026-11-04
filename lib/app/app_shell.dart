import 'package:flutter/material.dart';

import '../features/closet/closet_screen.dart';
import '../features/fit_check/fit_check_screen.dart';
import '../features/outfits/lookbook_screen.dart';
import '../features/outfits/outfit_request_screen.dart';
import '../features/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _titles = [
    'My Closet',
    'Get an Outfit',
    'Lookbook',
    'Fit Check',
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          ClosetScreen(),
          OutfitRequestScreen(),
          LookbookScreen(),
          FitCheckScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checkroom), label: 'Closet'),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: 'Outfits',
          ),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Lookbook'),
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            label: 'Fit Check',
          ),
        ],
      ),
    );
  }
}
