import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/startup_gate.dart';
import '../../core/data/backend_services.dart';
import '../../core/data/firebase_backend.dart';
import '../../core/logging/app_log.dart';
import '../closet/sample_closet.dart';
import 'my_data_deleter.dart';
import 'privacy_screen.dart';
import 'style_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.sampleLoader, this.deleter});

  /// Defaults to Member 1's loader on the app's closet.
  final SampleClosetLoader? sampleLoader;

  /// Defaults to deleting the signed-in user's data.
  final MyDataDeleter? deleter;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  BackendServices get _services {
    final scope = context.getInheritedWidgetOfExactType<BackendScope>();
    if (scope == null) throw StateError('No BackendScope above Settings.');
    return scope.services;
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadSampleCloset() async {
    AppLog.tap('Load sample closet', screen: 'Settings');
    setState(() => _busy = true);
    try {
      final closet = _services.closet;
      final items = await closet.getItems();
      if (!mounted) return;
      if (items.any((item) => item.isSample)) {
        _show('The sample closet is already loaded.');
        return;
      }
      final loader =
          widget.sampleLoader ?? SampleClosetLoader(repository: closet);
      await loader.load();
      if (!mounted) return;
      _show('Sample closet loaded. Find it in the Wardrobe tab.');
    } on Object catch (error) {
      AppLog.ui('Settings: sample closet failed: $error');
      if (!mounted) return;
      _show('Could not load the sample closet. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    AppLog.tap('Delete all my data', screen: 'Settings');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all your data?'),
        content: const Text(
          'This permanently deletes your closet, saved outfits, style '
          'profile, and the photos this app saved on your phone. It cannot '
          'be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      AppLog.ui('Settings: delete cancelled');
      return;
    }
    await _deleteAll();
  }

  Future<void> _deleteAll() async {
    setState(() => _busy = true);
    final deleter =
        widget.deleter ??
        MyDataDeleter(
          services: _services,
          ageConfirmation: AppDependencies.of(context).ageConfirmation,
        );
    try {
      await deleter.deleteAll();
    } on Object catch (error) {
      AppLog.ui('Settings: delete failed: $error');
      if (!mounted) return;
      setState(() => _busy = false);
      _show('Could not delete everything. Check your connection and retry.');
      return;
    }
    if (!mounted) return;
    // Start over at the welcome screen, as on a new install.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StartupGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.style),
                  title: const Text('Style profile'),
                  subtitle: const Text('Your style, colors, and occasions'),
                  onTap: () {
                    AppLog.tap('Style profile', screen: 'Settings');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StyleProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy'),
                  subtitle: const Text('What leaves your phone'),
                  onTap: () {
                    AppLog.tap('Privacy', screen: 'Settings');
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('Load sample closet'),
                  subtitle: const Text('18 tagged pieces to try the app'),
                  enabled: !_busy,
                  onTap: _loadSampleCloset,
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: const Text('Delete all my data'),
                  subtitle: const Text('Closet, outfits, profile, and photos'),
                  enabled: !_busy,
                  onTap: _confirmDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
