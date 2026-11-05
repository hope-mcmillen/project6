import 'dart:typed_data';

import '../data/models.dart';

abstract interface class AiService {
  /// Clothing-only photos. Do not send photos containing people on the free tier.
  Future<ClothingTags> tagClothing(Uint8List photoBytes);
  Future<List<Outfit>> generateOutfits(OutfitRequest request);
}

class AiServiceException implements Exception {
  const AiServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
