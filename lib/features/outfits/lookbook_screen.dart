import 'package:flutter/material.dart';

import '../../core/data/local_lookbook.dart';

class LookbookScreen extends StatefulWidget {
  const LookbookScreen({required this.store, this.onRemoved, super.key});

  final LocalLookbook store;
  final ValueChanged<String>? onRemoved;

  @override
  State<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends State<LookbookScreen> {
  late Future<LookbookData> _data = widget.store.read();
  String? _removing;
  String? _removeError;

  Future<void> _remove(String id) async {
    if (_removing != null) return;
    setState(() {
      _removing = id;
      _removeError = null;
    });
    try {
      await widget.store.remove(id);
      widget.onRemoved?.call(id);
      if (!mounted) return;
      setState(() {
        _data = widget.store.read();
      });
    } catch (_) {
      if (mounted) setState(() => _removeError = id);
    } finally {
      if (mounted) setState(() => _removing = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lookbook')),
    body: FutureBuilder<LookbookData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading saved outfits',
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load saved outfits.'),
                TextButton(
                  onPressed: () => setState(() {
                    _data = widget.store.read();
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final data = snapshot.requireData;
        if (data.outfits.isEmpty) {
          return const Center(child: Text('No saved outfits yet.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final outfit in data.outfits)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outfit.occasion,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(outfit.reason),
                      const SizedBox(height: 8),
                      for (final id in outfit.itemIds)
                        if (data.deletedItems.contains(id))
                          Text(
                            'Deleted item: $id',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          )
                        else
                          Text(id),
                      if (_removeError == outfit.id)
                        const Text('Could not remove this outfit. Try again.'),
                      TextButton.icon(
                        onPressed: _removing == null
                            ? () => _remove(outfit.id)
                            : null,
                        icon: const Icon(Icons.bookmark_remove_outlined),
                        label: Text(
                          _removing == outfit.id
                              ? 'Removing…'
                              : 'Remove outfit',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
