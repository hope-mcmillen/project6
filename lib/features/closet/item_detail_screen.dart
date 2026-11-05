import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/widgets/not_built.dart';
import 'closet_heading.dart';
import 'closet_photo.dart';
import 'closet_photo_picker.dart';
import 'closet_services.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.item,
    this.repository,
    this.deletePhoto = deleteClosetPhoto,
  });

  final ClothingItem item;
  final ClosetRepository? repository;
  final Future<void> Function(String photoPath) deletePhoto;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;

  Future<void> _removePhoto() async {
    try {
      await widget.deletePhoto(widget.item.photoPath);
    } on FileSystemException catch (error) {
      // The item is already gone, so a leftover file should not block the user.
      debugPrint('Could not delete closet photo: $error');
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This removes the item and its photo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Firestore removes the item from the closet right away but may not confirm
    // until the phone is online. The photo goes once the delete is confirmed.
    unawaited(
      _repository
          .deleteItem(widget.item.id)
          .then(
            (_) => _removePhoto(),
            onError: (Object _) => messenger
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Could not delete that item. Try again.'),
                ),
              ),
          ),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Item deleted')));
    Navigator.of(context).pop();
  }

  Widget _buildTag(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Not set' : capitalized(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name = itemName(item);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClosetPhoto(
            photoPath: item.photoPath,
            height: 240,
            fit: BoxFit.contain,
            semanticLabel: 'Photo of $name',
          ),
          const SizedBox(height: 16),
          ClosetCard(
            child: Column(
              children: [
                _buildTag('Category', categoryLabel(item.tags.category)),
                _buildTag('Color', item.tags.color),
                _buildTag('Pattern', item.tags.pattern),
                _buildTag('Formality', item.tags.formality),
                _buildTag('Season', item.tags.season),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => showNotBuilt(context, 'FR-3 edit saved tags'),
            child: const Text('Edit tags'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _confirmAndDelete,
            child: const Text('Delete item'),
          ),
        ],
      ),
    );
  }
}
