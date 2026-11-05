import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import 'add_item_screen.dart';
import 'closet_photo.dart';
import 'closet_repository.dart';
import 'clothing_item.dart';
import 'item_detail_screen.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key, this.repository});

  final ClosetRepository? repository;

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  static const _filters = ['All', 'Tops', 'Bottoms', 'Shoes'];

  late final ClosetRepository _repository =
      widget.repository ?? defaultClosetRepository;
  late final Stream<List<ClothingItem>> _items = _repository.watchItems();

  Widget _buildGrid(List<ClothingItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final item in items)
          Card(
            key: ValueKey(item.id),
            clipBehavior: .antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ItemDetailScreen(item: item, repository: _repository),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: ClosetPhoto(
                        photoPath: item.photoPath,
                        cacheWidth: 600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.name, maxLines: 1, overflow: .ellipsis),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCloset() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Your closet is empty. Add your first item to get started.',
        ),
      ),
    );
  }

  Widget _buildItems() {
    return StreamBuilder<List<ClothingItem>>(
      stream: _items,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load your closet.'));
        }
        final items = snapshot.data;
        if (items == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return items.isEmpty ? _buildEmptyCloset() : _buildGrid(items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddItemScreen(repository: _repository),
            ),
          );
        },
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: .horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                for (final filter in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: filter == 'All',
                      onSelected: (_) => showNotBuilt(context, 'FR-4 filters'),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildItems()),
        ],
      ),
    );
  }
}
