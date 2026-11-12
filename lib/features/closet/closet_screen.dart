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

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({
    super.key,
    this.repository,
    this.sampleLoader,
    this.onAddItem,
  });

  final ClosetRepository? repository;
  final SampleClosetLoader? sampleLoader;

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

  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;

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

  void _openItem(ClothingItem item) {
    AppLog.tap('${itemName(item)} (${item.id})', screen: 'Wardrobe');
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/item-detail'),
        builder: (_) => ItemDetailScreen(item: item, repository: _repository),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final label in _filters.keys)
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

  Widget _buildItemCard(ClothingItem item) {
    final name = itemName(item);
    final details = [
      item.tags.formality,
      item.tags.season,
    ].where((tag) => tag.isNotEmpty).map(capitalized).join(' · ');
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

  Widget _buildCloset(List<ClothingItem> allItems) {
    final category = _filters[_filter];
    final items = [
      for (final item in allItems)
        if (category == null || item.tags.category == category) item,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
                    child: Text('No ${_filter.toLowerCase()} in your closet.'),
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
