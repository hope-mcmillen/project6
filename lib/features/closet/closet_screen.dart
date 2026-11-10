import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import '../../core/logging/app_log.dart';
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

  /// A season filter also shows pieces tagged for every season.
  static const _allYear = 'all year';

  late final ClosetRepository _repository =
      widget.repository ?? closetServices(context).closet;
  late Stream<List<ClothingItem>> _items = _repository.watchItems();
  late final SampleClosetLoader _sampleLoader =
      widget.sampleLoader ?? SampleClosetLoader(repository: _repository);

  String _filter = 'All';
  String? _color;
  String? _season;
  bool _isLoadingSample = false;

  /// Tags are free text, so filters compare them trimmed and lowercase.
  static String _normalized(String tag) => tag.trim().toLowerCase();

  static List<String> _choices(
    List<ClothingItem> items,
    String Function(ClothingTags tags) tag,
  ) {
    return {
      for (final item in items)
        if (_normalized(tag(item.tags)) case final value when value.isNotEmpty)
          value,
    }.toList()..sort();
  }

  void _retryLoad() {
    AppLog.tap('Try again (closet failed to load)', screen: 'Wardrobe');
    setState(() => _items = _repository.watchItems());
  }

  Future<void> _clearSampleCloset(int sampleCount) async {
    AppLog.tap('Clear sample closet', screen: 'Wardrobe');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/clear-sample-dialog'),
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear the sample closet?'),
        content: Text(
          'This removes the $sampleCount sample '
          '${sampleCount == 1 ? 'piece' : 'pieces'} and their photos. Items '
          'you added stay.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLog.tap('Cancel', screen: 'Clear sample dialog');
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AppLog.tap('Clear', screen: 'Clear sample dialog');
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // The pieces leave the closet right away, but Firestore may not confirm
    // the deletes until the phone is online, so the screen does not wait.
    unawaited(
      _sampleLoader.clear().then(
        (cleared) => AppLog.ui('Sample closet cleared ($cleared items)'),
        onError: (Object error) {
          AppLog.ui('Sample closet FAILED to clear: $error');
          messenger
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text('Could not clear the sample closet. Try again.'),
              ),
            );
        },
      ),
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Sample closet cleared')),
    );
  }

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

  Widget _buildTagFilter({
    required String label,
    required List<String> choices,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    String shown(String? value) =>
        '$label: ${value == null ? 'Any' : capitalized(value)}';
    return DropdownButton<String?>(
      key: ValueKey('$label filter'),
      value: selected,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      selectedItemBuilder: (_) => [
        for (final value in [null, ...choices])
          Align(
            alignment: Alignment.centerLeft,
            child: Text(shown(value), overflow: .ellipsis),
          ),
      ],
      items: [
        DropdownMenuItem<String?>(child: Text('Any ${label.toLowerCase()}')),
        for (final value in choices)
          DropdownMenuItem(value: value, child: Text(capitalized(value))),
      ],
      onChanged: (value) {
        AppLog.tap('${shown(value)} filter', screen: 'Wardrobe');
        onChanged(value);
      },
    );
  }

  Widget _buildFilters({
    required List<String> colors,
    required List<String> seasons,
    required String? color,
    required String? season,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Wrap(
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
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTagFilter(
                label: 'Color',
                choices: colors,
                selected: color,
                onChanged: (value) => setState(() => _color = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTagFilter(
                label: 'Season',
                choices: seasons,
                selected: season,
                onChanged: (value) => setState(() => _season = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoMatches({required bool onlyCategory}) {
    if (onlyCategory) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text('No ${_filter.toLowerCase()} in your closet.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const Text('Nothing in your closet matches these filters.'),
          TextButton(
            onPressed: () {
              AppLog.tap('Clear filters', screen: 'Wardrobe');
              setState(() {
                _filter = 'All';
                _color = null;
                _season = null;
              });
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: .min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load your closet.', textAlign: .center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _retryLoad, child: const Text('Try again')),
          ],
        ),
      ),
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
    final colors = _choices(allItems, (tags) => tags.color);
    final seasons = _choices(allItems, (tags) => tags.season);
    // A chosen tag that no item has any more, such as after a delete, no
    // longer filters anything.
    final color = colors.contains(_color) ? _color : null;
    final season = seasons.contains(_season) ? _season : null;
    final category = _filters[_filter];

    bool matches(ClothingItem item) {
      final itemSeason = _normalized(item.tags.season);
      return (category == null || item.tags.category == category) &&
          (color == null || _normalized(item.tags.color) == color) &&
          (season == null ||
              itemSeason == season ||
              (itemSeason == _allYear && season != _allYear));
    }

    final items = allItems.where(matches).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final count = allItems.length;
    final sampleCount = allItems.where((item) => item.isSample).length;

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
                if (count == 0)
                  _buildEmptyCloset()
                else
                  _buildFilters(
                    colors: colors,
                    seasons: seasons,
                    color: color,
                    season: season,
                  ),
                if (sampleCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear sample closet'),
                      onPressed: () => _clearSampleCloset(sampleCount),
                    ),
                  ),
                if (count > 0 && items.isEmpty)
                  _buildNoMatches(
                    onlyCategory: color == null && season == null,
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
        stream: _items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            AppLog.ui('Wardrobe: closet failed to load: ${snapshot.error}');
            return _buildLoadError();
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
