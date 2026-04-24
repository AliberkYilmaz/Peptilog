import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps [Connectivity] and exposes a broadcast stream of online status.
///
/// Online is defined as having at least one active wifi or mobile connection.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  /// Emits `true` when the device is online, `false` when offline.
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map((results) => _isOnline(results));

  /// Returns the current online status as a one-shot future.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
}
