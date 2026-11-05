import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import 'closet_photo.dart';
import 'closet_photo_picker.dart';
import 'closet_repository.dart';
import 'clothing_item.dart';

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
      widget.repository ?? defaultClosetRepository;
  bool _isDeleting = false;

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

    setState(() => _isDeleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.deleteItem(widget.item.id);
    } on Exception {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete this item. Try again.')),
      );
      return;
    }

    try {
      await widget.deletePhoto(widget.item.photoPath);
    } on FileSystemException catch (error) {
      // The item is already gone, so a leftover file should not block the user.
      debugPrint('Could not delete closet photo: $error');
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Item deleted')));
    Navigator.of(context).pop();
  }

  Widget _buildTag(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Not set' : value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClosetPhoto(
            photoPath: item.photoPath,
            height: 240,
            fit: BoxFit.contain,
            semanticLabel: 'Photo of ${item.name}',
          ),
          const SizedBox(height: 8),
          _buildTag('Category', item.tags.category),
          _buildTag('Color', item.tags.color),
          _buildTag('Pattern', item.tags.pattern),
          _buildTag('Formality', item.tags.formality),
          _buildTag('Season', item.tags.season),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showNotBuilt(context, 'FR-3 edit saved tags'),
            child: const Text('Edit tags'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isDeleting ? null : _confirmAndDelete,
            child: const Text('Delete item'),
          ),
        ],
      ),
    );
  }
}
