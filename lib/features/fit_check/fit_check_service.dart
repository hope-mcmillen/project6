import 'dart:typed_data';

import '../../core/ai/ai_service.dart';
import '../../core/data/models.dart';

/// What Fit Check sends to the AI: one outfit photo with no person in it.
class FitCheckRequest {
  const FitCheckRequest({
    required this.photo,
    required this.occasion,
    this.weather,
  });

  /// JPEG bytes, already resized with `resizePhotoForAi`.
  final Uint8List photo;
  final String occasion;
  final WeatherSummary? weather;
}

/// The AI's verdict plus up to 3 specific suggestions about the clothes.
class FitCheckFeedback {
  FitCheckFeedback({required this.verdict, required List<String> suggestions})
    : suggestions = List.unmodifiable(suggestions.take(3));

  final String verdict;
  final List<String> suggestions;
}

/// Member 3 implements this with Firebase AI Logic in M3-09 and passes it to
/// `FitCheckScreen`. Feedback must cover clothing only, never body shape,
/// weight, or skin. Throw [AiServiceException] with a user-facing message on
/// failure.
abstract interface class FitCheckService {
  Future<FitCheckFeedback> checkFit(FitCheckRequest request);
}

/// Used until M3-09 is merged, so the screens show a clear message instead of
/// sample feedback.
class PendingFitCheckService implements FitCheckService {
  const PendingFitCheckService();

  @override
  Future<FitCheckFeedback> checkFit(FitCheckRequest request) async {
    throw const AiServiceException(
      'Fit Check feedback is not connected yet. Please try again later.',
    );
  }
}

/// A predictable service for tests and for building screens without Firebase.
class FakeFitCheckService implements FitCheckService {
  FakeFitCheckService({this.failuresBeforeSuccess = 0});

  /// How many calls fail before one succeeds.
  int failuresBeforeSuccess;
  int calls = 0;
  FitCheckRequest? lastRequest;

  @override
  Future<FitCheckFeedback> checkFit(FitCheckRequest request) async {
    calls++;
    lastRequest = request;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw const AiServiceException(
        'AI is unavailable. Check your connection and retry.',
      );
    }
    return FitCheckFeedback(
      verdict: 'Works well for ${request.occasion.toLowerCase()}.',
      suggestions: const [
        'Swap the sneakers for loafers to look a little sharper.',
        'Tuck in the shirt to balance the proportions.',
        'Add a belt that matches your shoes.',
      ],
    );
  }
}
