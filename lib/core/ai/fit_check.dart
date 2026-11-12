import 'dart:typed_data';

import '../data/models.dart';

/// One clothing-only outfit photo, its occasion and optional weather context.
class FitCheckRequest {
  const FitCheckRequest({
    required this.photo,
    required this.occasion,
    this.weather,
  });

  /// JPEG bytes prepared with Member 4's shared photo helper.
  final Uint8List photo;
  final String occasion;
  final WeatherSummary? weather;
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
