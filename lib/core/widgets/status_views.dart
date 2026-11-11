import 'package:flutter/material.dart';

/// A centered spinner with an optional message, for any screen that waits.
///
/// ```dart
/// if (loading) return const LoadingView(message: 'Suggesting tags...');
/// ```
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(semanticsLabel: text ?? 'Loading'),
            if (text != null) ...[
              const SizedBox(height: 16),
              Text(text, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// An error message with a Retry button.
///
/// Pass the message the user should read, such as an
/// `AiServiceException.message`, and what to run again.
///
/// ```dart
/// ErrorRetryView(message: error.message, onRetry: _loadOutfits)
/// ```
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final IconData icon;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of an AI feature when the phone has no connection.
///
/// The closet still works offline, so this only blocks AI screens.
class OfflineView extends StatelessWidget {
  const OfflineView({super.key, this.onRetry});

  static const message =
      'You are offline. Your closet still works, but AI features need a '
      'connection.';

  /// Optional. When given, shows a Try again button.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    if (retry != null) {
      return ErrorRetryView(
        message: message,
        onRetry: retry,
        icon: Icons.wifi_off,
        retryLabel: 'Try again',
      );
    }
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
