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
import 'wear_stats.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.item,
    this.repository,
    this.wearLogs,
    this.deletePhoto = deleteClosetPhoto,
    this.now = DateTime.now,
  });

  final ClothingItem item;
  final ClosetRepository? repository;
  final WearLogRepository? wearLogs;
  final Future<void> Function(String photoPath) deletePhoto;
  final DateTime Function() now;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;
  late final WearLogRepository _wearLogs =
      widget.wearLogs ?? closetServices(context).wearLogs;

  /// Null until the wear history loads.
  List<WearLog>? _logs;
  bool _wearFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadWear());
  }

  Future<void> _loadWear() async {
    try {
      final logs = await _wearLogs.getWearLogs();
      if (mounted) setState(() => _logs = logs);
    } on Exception catch (error) {
      AppLog.ui('Item Detail: could not load wear history: $error');
      if (mounted) setState(() => _wearFailed = true);
    }
  }

  void _retryWear() {
    AppLog.tap('Retry wear history', screen: 'Item Detail');
    setState(() => _wearFailed = false);
    unawaited(_loadWear());
  }

  void _undoWear(WearLog log) {
    if (!mounted) return;
    setState(() => _logs = [...?_logs]..removeWhere((l) => l.id == log.id));
  }

  void _woreToday(List<WearLog> logs) {
    AppLog.tap('Wore this today', screen: 'Item Detail');
    // A single-item wear has no outfit. Outfit wears from M2-07 set outfitId.
    final log = WearLog(
      id: newClosetId(),
      outfitId: '',
      itemIds: [widget.item.id],
      wornAt: widget.now(),
    );
    setState(() => _logs = [...logs, log]);
    final messenger = ScaffoldMessenger.of(context);
    // Like closet saves, an offline write only confirms after reconnecting,
    // so the screen updates now and undoes the wear if the write fails.
    unawaited(
      _wearLogs.saveWearLog(log).catchError((Object error) {
        AppLog.ui('Item Detail: could not save the wear: $error');
        _undoWear(log);
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not log that wear. Try again.'),
            ),
          );
      }),
    );
  }

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

  Widget _buildWear() {
    final logs = _logs;
    if (_wearFailed) {
      return ClosetCard(
        child: Row(
          children: [
            const Expanded(child: Text('Could not load wear history.')),
            TextButton(onPressed: _retryWear, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (logs == null) {
      return const ClosetCard(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final now = widget.now();
    final stats = WearStats(logs);
    final wear = stats.forItem(widget.item.id);
    final wornToday = stats.wornOn(widget.item.id, now);
    return ClosetCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _buildTag('Times worn', timesWornLabel(wear.count)),
          _buildTag('Last worn', lastWornLabel(wear.lastWorn, now)),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: wornToday ? null : () => _woreToday(logs),
            child: Text(wornToday ? 'Worn today' : 'Wore this today'),
          ),
        ],
      ),
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
          _buildWear(),
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
