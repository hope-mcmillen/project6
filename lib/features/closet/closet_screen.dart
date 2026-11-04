import 'package:flutter/material.dart';

import '../../core/widgets/not_built.dart';
import '../../core/widgets/photo_placeholder.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

  static const _filters = ['All', 'Tops', 'Bottoms', 'Shoes'];
  static const _sampleItems = [
    'Blue T-shirt',
    'White button-up',
    'Black jeans',
    'Khaki chinos',
    'White sneakers',
    'Brown boots',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AddItemScreen()));
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
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final item in _sampleItems)
                  Card(
                    clipBehavior: .antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(name: item),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Expanded(child: PhotoPlaceholder()),
                            const SizedBox(height: 8),
                            Text(item, maxLines: 1, overflow: .ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
