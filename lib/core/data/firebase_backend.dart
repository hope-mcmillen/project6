import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';
import '../logging/app_log.dart';
import '../logging/logging_backend.dart';
import 'backend_services.dart';

/// The shared bundle is available to every screen without recreating repositories.
class BackendScope extends InheritedWidget {
  const BackendScope({required this.services, required super.child, super.key});
  final BackendServices services;

  static BackendServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BackendScope>();
    if (scope == null) throw StateError('No BackendScope above this screen.');
    return scope.services;
  }

  @override
  bool updateShouldNotify(BackendScope oldWidget) =>
      services != oldWidget.services;
}

Future<BackendServices> connectFirebaseBackend() async {
  final options = DefaultFirebaseOptions.currentPlatform;
  final watch = Stopwatch()..start();
  AppLog.app('Connecting to Firebase project ${options.projectId}...');
  try {
    final services = await BackendServices.connect(options: options);
    // The uid is the Firestore folder: users/{uid}/items. Never log tokens.
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    AppLog.app(
      'Connected in ${watch.elapsedMilliseconds} ms. '
      'App Check: ${kDebugMode ? 'debug provider' : 'Play Integrity'}. '
      'Signed in anonymously, uid $uid',
    );
    return withLogging(services);
  } on Object catch (error) {
    AppLog.app(
      'Firebase connect FAILED after ${watch.elapsedMilliseconds} ms: $error',
    );
    rethrow;
  }
}

/// Firebase startup only. Keith retains the welcome/age-confirmation flow.
class FirebaseBackend extends StatefulWidget {
  const FirebaseBackend({
    required this.child,
    this.load = connectFirebaseBackend,
    super.key,
  });
  final Widget child;
  final Future<BackendServices> Function() load;
  @override
  State<FirebaseBackend> createState() => _FirebaseBackendState();
}

class _FirebaseBackendState extends State<FirebaseBackend> {
  late Future<BackendServices> _services;
  @override
  void initState() {
    super.initState();
    _services = Future.sync(widget.load);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<BackendServices>(
    future: _services,
    builder: (context, snapshot) {
      final services = snapshot.data;
      if (services != null) {
        return BackendScope(services: services, child: widget.child);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Could not connect. Check your connection and try again.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            AppLog.tap('Retry', screen: 'Connection error');
                            setState(() {
                              _services = Future.sync(widget.load);
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(
                      semanticsLabel: 'Connecting to your closet',
                    ),
            ),
          ),
        ),
      );
    },
  );
}
