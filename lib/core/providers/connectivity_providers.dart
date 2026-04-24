import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

/// Emits `true` when the device is online (wifi / mobile / ethernet).
/// Emits `false` when offline or when connectivity cannot be determined.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onlineStream;
});
