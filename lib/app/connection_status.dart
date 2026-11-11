import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the phone has a network connection. Tests use a fake.
abstract interface class ConnectionStatus {
  Future<bool> isOnline();

  /// Emits true when a connection returns and false when it is lost.
  Stream<bool> get onlineChanges;
}

/// The phone's real connection, from `connectivity_plus`.
///
/// This reports whether Wi-Fi or mobile data is on, not whether a server can
/// be reached, which is enough to warn that AI features need a connection.
class DeviceConnectionStatus implements ConnectionStatus {
  const DeviceConnectionStatus();

  static bool _online(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await Connectivity().checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      Connectivity().onConnectivityChanged.map(_online);
}
