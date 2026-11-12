import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../closet/closet_photo.dart';

class OutfitResultsScreen extends StatelessWidget {
  const OutfitResultsScreen({
    required this.outfits,
    required this.closet,
    super.key,
  });

  final List<Outfit> outfits;
  final List<ClothingItem> closet;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final item in closet) item.id: item};
    return Scaffold(
      appBar: AppBar(title: const Text('Your Outfits')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: outfits.length,
        itemBuilder: (context, index) {
          final outfit = outfits[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outfit ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(outfit.reason),
                  const SizedBox(height: 12),
                  for (final id in outfit.itemIds)
                    if (byId[id] case final item?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.tags.color} ${item.tags.category}'.trim(),
                            ),
                            if (!item.isSample && item.photoPath.isNotEmpty)
                              ClosetPhoto(
                                photoPath: item.photoPath,
                                height: 96,
                                fit: BoxFit.contain,
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
