import 'dart:typed_data';

import '../data/models.dart';

/// One clothing-only outfit photo, its occasion and optional weather context.
class FitCheckRequest {
  const FitCheckRequest({
    required this.photo,
    required this.occasion,
    this.weather,
    this.clothingOnlyConfirmed = false,
  });

  /// Image bytes. The live service re-encodes them with the shared photo helper.
  final Uint8List photo;
  final String occasion;
  final WeatherSummary? weather;

  /// Set only after the user confirms this specific photo shows no people.
  /// This is an acknowledgement, not an on-device person detector. There is no
  /// paid-tier bypass; an unconfirmed photo must not reach the provider.
  final bool clothingOnlyConfirmed;

  static const photoPolicyMessage =
      'Confirm this photo shows only clothing, with no person in the frame. '
      'Use an outfit laid flat or on a hanger.';

  /// Shared by the live service and fake, before photo work or quota reservation.
  String? get validationError {
    if (!clothingOnlyConfirmed) return photoPolicyMessage;
    if (photo.isEmpty) return 'Choose an outfit photo first.';
    if (occasion.trim().isEmpty || occasion.length > 160) {
      return 'Choose an occasion of 1 to 160 characters.';
    }
    final context = weather;
    if (context != null &&
        (!context.temperatureC.isFinite ||
            context.rainChancePercent < 0 ||
            context.rainChancePercent > 100)) {
      return 'Weather could not be read. Refresh it or retry without weather.';
    }
    return null;
  }
}

/// Feedback about clothing, with at most three specific suggestions.
class FitCheckFeedback {
  FitCheckFeedback({required this.verdict, required List<String> suggestions})
    : suggestions = List.unmodifiable(suggestions.take(3));

  final String verdict;
  final List<String> suggestions;

  /// Strict validation for untrusted structured model replies.
  /// The display constructor retains its existing three-suggestion cap.
  factory FitCheckFeedback.fromMap(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a Fit Check object.');
    }
    final suggestions = value['suggestions'];
    if (suggestions is! List || suggestions.length > 3) {
      throw const FormatException('Expected up to three clothing suggestions.');
    }
    return FitCheckFeedback(
      verdict: _text(value['verdict'], max: 600),
      suggestions: [
        for (final suggestion in suggestions) _text(suggestion, max: 200),
      ],
    );
  }

  static String _text(Object? value, {required int max}) {
    if (value is! String || value.trim().isEmpty || value.length > max) {
      throw const FormatException(
        'Expected short, nonempty clothing feedback.',
      );
    }
    return value.trim();
  }
}

/// Screens can accept either a dedicated implementation or the shared AiService.
/// Feedback covers clothing only, with failures reported as AiServiceException.
abstract interface class FitCheckService {
  Future<FitCheckFeedback> checkFit(FitCheckRequest request);
}
