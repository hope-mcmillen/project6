import 'package:flutter/material.dart';

import '../../core/data/local_lookbook.dart';
import '../../core/data/models.dart';

class OutfitResultsScreen extends StatelessWidget {
  const OutfitResultsScreen({this.outfit, this.outfits, this.store, super.key});

  final Outfit? outfit;
  final List<Outfit>? outfits;
  final LocalLookbook? store;

  // The preview uses fixed wardrobe labels as identifiers.
  static Outfit sampleOutfit() => Outfit(
    id: 'weekend-edit',
    itemIds: const ['Linen shirt', 'Everyday shorts', 'Green sneakers'],
    reason: 'A relaxed combination for your plans.',
    occasion: 'The Weekend Edit',
    createdAt: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final results = outfits ?? [outfit ?? sampleOutfit()];
    final lookbook = store ?? LocalLookbook();
    return Scaffold(
      appBar: AppBar(title: const Text('Your Outfits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final result in results)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.occasion,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(result.reason),
                    const SizedBox(height: 12),
                    for (final item in result.itemIds) Text(item),
                    const SizedBox(height: 16),
                    SaveOutfitButton(outfit: result, store: lookbook),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SaveOutfitButton extends StatefulWidget {
  const SaveOutfitButton({
    required this.outfit,
    required this.store,
    this.label = 'Save',
    this.savedLabel = 'Saved',
    super.key,
  });

  final Outfit outfit;
  final LocalLookbook store;
  final String label;
  final String savedLabel;

  @override
  State<SaveOutfitButton> createState() => _SaveOutfitButtonState();
}

class _SaveOutfitButtonState extends State<SaveOutfitButton> {
  bool _saving = false;
  bool _saved = false;
  bool _failed = false;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.store.save(widget.outfit);
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_failed) const Text('Could not save this outfit. Try again.'),
      FilledButton.icon(
        onPressed: _saving || _saved ? null : _save,
        icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
        label: Text(
          _saving
              ? 'Saving…'
              : _saved
              ? widget.savedLabel
              : widget.label,
        ),
      ),
    ],
  );
}
