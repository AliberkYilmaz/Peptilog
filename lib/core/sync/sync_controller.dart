import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_service.dart';

/// Wires sync triggers 2–4 (app resume, connectivity flip, periodic 15 min).
///
/// Trigger 1 (on write) is handled at the repository level — each Isar
/// repository fires [SyncController.onRecordWritten] via its [onMutated]
/// callback after a successful write.
///
/// Usage: create once via [syncControllerProvider], call [init] from the root
/// widget's [initState], and [dispose] in its dispose.
class SyncController with WidgetsBindingObserver {
  SyncController({
    required SyncService syncService,
    required Stream<bool> onlineStream,
  }) : _syncService = syncService,
       _onlineStream = onlineStream;

  final SyncService _syncService;
  final Stream<bool> _onlineStream;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _periodicTimer;
  bool _wasOnline = true;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = _onlineStream.listen(_onConnectivityChanged);
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _triggerSync(),
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Trigger 1 — on write (called by Isar repo onMutated callbacks)
  // ---------------------------------------------------------------------------

  void onRecordWritten() => _triggerSync();

  // ---------------------------------------------------------------------------
  // Trigger 2 — app resume
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _triggerSync();
  }

  // ---------------------------------------------------------------------------
  // Trigger 3 — connectivity restored (false → true)
  // ---------------------------------------------------------------------------

  void _onConnectivityChanged(bool isOnline) {
    if (isOnline && !_wasOnline) _triggerSync();
    _wasOnline = isOnline;
  }

  // ---------------------------------------------------------------------------
  // Trigger 4 — 15-minute periodic (handled by _periodicTimer above)
  // ---------------------------------------------------------------------------

  void _triggerSync() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return; // not authenticated — skip
    _syncService.sync(userId); // fire-and-forget
  }
}
