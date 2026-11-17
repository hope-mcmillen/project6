import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
import '../../core/widgets/status_views.dart';
import 'add_item_screen.dart';
import 'closet_heading.dart';
import 'closet_photo.dart';
import 'closet_services.dart';
import 'item_detail_screen.dart';
import 'sample_closet.dart';
import 'wear_stats.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({
    super.key,
    this.repository,
    this.wearLogs,
    this.sampleLoader,
    this.onAddItem,
    this.now = DateTime.now,
  });

  final ClosetRepository? repository;
  final WearLogRepository? wearLogs;
  final SampleClosetLoader? sampleLoader;
  final DateTime Function() now;

  /// Opens the app's add item tab. Without it, the screen pushes its own.
  final VoidCallback? onAddItem;

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  static const _filters = {
    'All': null,
    'Tops': 'top',
    'Bottoms': 'bottom',
    'Dresses': 'dress',
    'Shoes': 'shoes',
    'Outerwear': 'outerwear',
    'Accessories': 'accessory',
  };

  /// Shows items not worn in [WearStats.staleDays], instead of a category.
  static const _notWornFilter = 'Not worn lately';

  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;
  late final WearLogRepository _wearLogs =
      widget.wearLogs ?? closetServices(context).wearLogs;

  /// Null until the wear history loads, or if it failed to load.
  WearStats? _wearStats;
  bool _wearFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadWear());
  }

  Future<void> _loadWear() async {
    try {
      final logs = await _wearLogs.getWearLogs();
      if (!mounted) return;
      setState(() {
        _wearStats = WearStats(logs);
        _wearFailed = false;
      });
    } on Exception catch (error) {
      AppLog.ui('Wardrobe: could not load wear history: $error');
      if (mounted) setState(() => _wearFailed = true);
    }
  }

  void _retryWear() {
    AppLog.tap('Retry wear history', screen: 'Wardrobe');
    setState(() => _wearFailed = false);
    unawaited(_loadWear());
  }

  /// Replaced by [_retryLoad], because a stream that has failed stays closed.
  late Stream<List<ClothingItem>> _items = _repository.watchItems();
  late final SampleClosetLoader _sampleLoader =
      widget.sampleLoader ?? SampleClosetLoader(repository: _repository);

  String _filter = 'All';
  bool _isLoadingSample = false;

  Future<void> _loadSampleCloset() async {
    AppLog.tap('Load sample closet', screen: 'Wardrobe');
    setState(() => _isLoadingSample = true);
    final watch = Stopwatch()..start();
    try {
      await _sampleLoader.load();
      AppLog.ui(
        'Sample closet loaded (${sampleClothes.length} items) in '
        '${watch.elapsedMilliseconds} ms',
      );
    } on Exception catch (error) {
      AppLog.ui('Sample closet FAILED to load: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the sample closet.')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingSample = false);
    }
  }

  void _retryLoad() {
    AppLog.tap('Retry loading closet', screen: 'Wardrobe');
    setState(() => _items = _repository.watchItems());
  }

  void _addItem() {
    AppLog.tap('Add item', screen: 'Wardrobe');
    final onAddItem = widget.onAddItem;
    if (onAddItem != null) return onAddItem();
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/add-item'),
        builder: (_) => AddItemScreen(repository: _repository),
      ),
    );
  }

  Future<void> _openItem(ClothingItem item) async {
    AppLog.tap('${itemName(item)} (${item.id})', screen: 'Wardrobe');
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/item-detail'),
        builder: (_) => ItemDetailScreen(
          item: item,
          repository: _repository,
          wearLogs: _wearLogs,
          now: widget.now,
        ),
      ),
    );
    // The item may have been worn on its details screen.
    if (mounted) await _loadWear();
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final label in [..._filters.keys, _notWornFilter])
          ChoiceChip(
            label: Text(label),
            selected: _filter == label,
            onSelected: (_) {
              AppLog.tap('Filter: $label', screen: 'Wardrobe');
              setState(() => _filter = label);
            },
          ),
      ],
    );
  }

  /// The card's second line: when it was last worn under the wear filter,
  /// otherwise its formality and season.
  String _cardDetails(ClothingItem item) {
    final stats = _wearStats;
    if (_filter == _notWornFilter && stats != null) {
      final lastWorn = stats.forItem(item.id).lastWorn;
      return lastWorn == null
          ? 'Never worn'
          : 'Last worn ${lastWornLabel(lastWorn, widget.now()).toLowerCase()}';
    }
    return [
      item.tags.formality,
      item.tags.season,
    ].where((tag) => tag.isNotEmpty).map(capitalized).join(' · ');
  }

  Widget _buildItemCard(ClothingItem item) {
    final name = itemName(item);
    final details = _cardDetails(item);
    return InkWell(
      key: ValueKey(item.id),
      borderRadius: BorderRadius.circular(22),
      onTap: () => _openItem(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEEE8F4)),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: ClosetPhoto(photoPath: item.photoPath, cacheWidth: 600),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: .ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                details,
                maxLines: 1,
                overflow: .ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCloset() {
    return ClosetCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          const Text(
            'Your closet is empty. Add your first item to get started, or '
            'try the app with a sample closet.',
            textAlign: .center,
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoadingSample ? null : _loadSampleCloset,
            child: const Text('Load sample closet'),
          ),
        ],
      ),
    );
  }

  List<ClothingItem> _filtered(List<ClothingItem> allItems) {
    if (_filter == _notWornFilter) {
      final stats = _wearStats;
      if (stats == null) return [];
      final now = widget.now();
      return [
        for (final item in allItems)
          if (stats.notWornLately(item, now)) item,
      ];
    }
    final category = _filters[_filter];
    return [
      for (final item in allItems)
        if (category == null || item.tags.category == category) item,
    ];
  }

  /// Shown under the filters when the chosen filter matches nothing.
  Widget _buildNoMatches() {
    if (_filter != _notWornFilter) {
      return Text('No ${_filter.toLowerCase()} in your closet.');
    }
    if (_wearFailed) {
      return Row(
        children: [
          const Expanded(child: Text('Could not load wear history.')),
          TextButton(onPressed: _retryWear, child: const Text('Retry')),
        ],
      );
    }
    if (_wearStats == null) return const LinearProgressIndicator();
    return const Text(
      'Everything has been worn in the last ${WearStats.staleDays} days.',
    );
  }

  Widget _buildCloset(List<ClothingItem> allItems) {
    final items = _filtered(allItems)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final count = allItems.length;

    return CustomScrollView(
      key: const PageStorageKey('closet'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                ClosetHeading(
                  eyebrow: 'THE CLOSET',
                  title: 'Your wardrobe',
                  subtitle: count == 0
                      ? 'Every piece you add shows up here.'
                      : '$count ${count == 1 ? 'piece' : 'pieces'} to make '
                            'your own. Tap a piece to see its tags.',
                ),
                if (count == 0) _buildEmptyCloset() else _buildFilters(),
                if (count > 0 && items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _buildNoMatches(),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
          sliver: SliverGrid.builder(
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisExtent: 238,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, i) => _buildItemCard(items[i]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
        onPressed: _addItem,
      ),
      body: StreamBuilder<List<ClothingItem>>(
        // A new key per stream starts each retry from a clean loading state,
        // rather than keeping the previous error on screen.
        key: ObjectKey(_items),
        stream: _items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetryView(
              message:
                  'Could not load your closet. Check your connection '
                  'and try again.',
              onRetry: _retryLoad,
            );
          }
          final items = snapshot.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCloset(items);
        },
      ),
    );
  }
}
