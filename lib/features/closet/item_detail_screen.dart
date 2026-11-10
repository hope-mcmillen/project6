import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
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
      AppLog.ui('Item Detail: deleted the photo file for ${widget.item.id}');
    } on FileSystemException catch (error) {
      // The item is already gone, so a leftover file should not block the user.
      AppLog.ui('Item Detail: could not delete the photo file: $error');
    }
  }

  Future<void> _confirmAndDelete() async {
    AppLog.tap('Delete item', screen: 'Item Detail');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/delete-item-dialog'),
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This removes the item and its photo.'),
        actions: [
          TextButton(
            onPressed: () {
              AppLog.tap('Cancel', screen: 'Delete item dialog');
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AppLog.tap('Delete', screen: 'Delete item dialog');
              Navigator.of(dialogContext).pop(true);
            },
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
            onPressed: () {
              AppLog.tap('Edit tags (not built yet)', screen: 'Item Detail');
              showNotBuilt(context, 'FR-3 edit saved tags');
            },
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
