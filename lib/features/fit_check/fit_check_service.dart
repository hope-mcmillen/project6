import '../../core/ai/ai_service.dart';

export '../../core/ai/fit_check.dart';

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
