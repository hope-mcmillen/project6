import 'dart:typed_data';

import '../data/models.dart';
import 'fit_check.dart';

export 'fit_check.dart';

abstract interface class AiService implements FitCheckService {
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
