import 'dart:async';

import 'package:flutter/material.dart';

import '../core/logging/app_log.dart';
import '../core/widgets/status_views.dart';
import 'connection_status.dart';

/// A banner across the top of every tab while the phone is offline.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.connection});

  final ConnectionStatus connection;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<bool>? _changes;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _changes = widget.connection.onlineChanges.listen(
      _update,
      // If the platform cannot report the connection, show no banner.
      onError: (Object error) =>
          AppLog.app('Connection status unavailable: $error'),
    );
    widget.connection.isOnline().then(
      _update,
      onError: (Object error) =>
          AppLog.app('Connection status unavailable: $error'),
    );
  }

  void _update(bool online) {
    if (!mounted || online == _online) return;
    AppLog.app(online ? 'Back online' : 'Went offline');
    setState(() => _online = online);
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: _online
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: colors.errorContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: colors.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        OfflineView.message,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
