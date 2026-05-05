import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// path_provider removed from main.dart — writeBreadcrumbs now uses direct sync writes
// to avoid MethodChannel hang before WidgetsFlutterBinding is initialized.
// sentry_flutter temporarily removed for crash diagnosis (PEP-78)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/database/isar_database.dart';
import 'core/database/seed_service.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/sync_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/sync/sync_controller.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  // Stage 4 marker — sync write before anything else so we know Dart main() was entered.
  try {
    File('/storage/emulated/0/Download/app-stage-4-dartMain.txt')
        .writeAsStringSync('dart main entered at ${DateTime.now().toIso8601String()}\n');
  } catch (_) {}

  WidgetsFlutterBinding.ensureInitialized();

  // Stage 5: proves WidgetsFlutterBinding completed (sync path, no plugin needed)
  try {
    File('/storage/emulated/0/Download/app-stage-5-bindingReady.txt')
        .writeAsStringSync('binding ready at ${DateTime.now().toIso8601String()}\n');
  } catch (_) {}

  // DIAGNOSTIC: per-stage breadcrumb log + 15s timeouts.
  // writeBreadcrumbs is synchronous and uses a direct path write to avoid
  // MethodChannel hang — getApplicationDocumentsDirectory() blocks forever when
  // the platform channel handler isn't bound yet (found in versionCode 8).
  String stage = 'pre-init';
  final breadcrumbs = StringBuffer(
    '=== Peptilog boot ${DateTime.now().toIso8601String()} ===\n',
  );

  void writeBreadcrumbs([String suffix = '']) {
    try {
      File('/storage/emulated/0/Download/peptilog-boot.txt')
          .writeAsStringSync('${breadcrumbs.toString()}$suffix');
    } catch (_) {}
  }

  Future<T> step<T>(
    String name,
    Future<T> Function() body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    stage = name;
    final t0 = DateTime.now();
    breadcrumbs.writeln('[${t0.toIso8601String().substring(11, 19)}] STARTED $name');
    writeBreadcrumbs();
    try {
      final result = await body().timeout(
        timeout,
        onTimeout: () => throw TimeoutException('$name exceeded $timeout'),
      );
      final ms = DateTime.now().difference(t0).inMilliseconds;
      breadcrumbs.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] OK $name (${ms}ms)');
      writeBreadcrumbs();
      return result;
    } catch (e) {
      breadcrumbs.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] FAILED $name: $e');
      writeBreadcrumbs();
      rethrow;
    }
  }

  try {
    await step('Firebase.initializeApp', () => Firebase.initializeApp());

    await step('Supabase.initialize', () => Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    ));

    final isar = await step('IsarDatabase.open', () => IsarDatabase.open());

    await step('SeedService.seedPresetsIfNeeded',
        () => SeedService(isar).seedPresetsIfNeeded());

    final notificationLaunchRoute = await step(
        'NotificationService.initialize', () => NotificationService.initialize());

    final prefs = await step(
        'SharedPreferences.getInstance', () => SharedPreferences.getInstance());

    breadcrumbs.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] runApp');
    writeBreadcrumbs();

    // DIAG_HELLO=true bypasses the full widget tree to confirm Flutter rendering works.
    // If "HELLO" renders → Flutter is fine, bug is in PeptilogApp/router.
    // If C-splash persists → Flutter rendering pipeline itself is stuck.
    const bool diagHello = bool.fromEnvironment('DIAG_HELLO');
    if (diagHello) {
      runApp(const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              'HELLO from Peptilog versionCode 10 diag\nFlutter rendering OK',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green, fontSize: 20, fontFamily: 'monospace'),
            ),
          ),
        ),
      ));
      return;
    }

    // sentry_flutter temporarily removed for crash diagnosis (PEP-78)
    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: PeptilogApp(notificationLaunchRoute: notificationLaunchRoute),
      ),
    );
  } catch (e, st) {
    breadcrumbs.writeln('FATAL $stage: $e\n$st');
    writeBreadcrumbs();
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PEPTILOG BOOT FAILURE',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'STAGE: $stage',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$e\n$st',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class PeptilogApp extends ConsumerStatefulWidget {
  const PeptilogApp({super.key, this.notificationLaunchRoute});

  /// Non-null when the app was cold-launched by tapping a notification.
  final String? notificationLaunchRoute;

  @override
  ConsumerState<PeptilogApp> createState() => _PeptilogAppState();
}

class _PeptilogAppState extends ConsumerState<PeptilogApp> {
  late SyncController _syncController;
  StreamSubscription<String>? _notifTapSub;

  @override
  void initState() {
    super.initState();
    try {
      File('/storage/emulated/0/Download/widget-stage-2-initState.txt')
          .writeAsStringSync('initState entered at ${DateTime.now().toIso8601String()}\n');
    } catch (_) {}
    _syncController = ref.read(syncControllerProvider);
    _syncController.init();
    try {
      File('/storage/emulated/0/Download/widget-stage-3-syncInit.txt')
          .writeAsStringSync('SyncController.init done at ${DateTime.now().toIso8601String()}\n');
    } catch (_) {}

    // Navigate to the payload route when a notification is tapped.
    _notifTapSub = NotificationService.tapRoute.listen((route) {
      final router = ref.read(appRouterProvider);
      router.go(route);
    });

    // If the app was cold-launched by a notification tap, navigate once the
    // router is ready (after the first frame so the redirect logic can run).
    if (widget.notificationLaunchRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = ref.read(appRouterProvider);
        router.go(widget.notificationLaunchRoute!);
      });
    }
  }

  @override
  void dispose() {
    _syncController.dispose();
    _notifTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      File('/storage/emulated/0/Download/widget-stage-1-appBuild.txt')
          .writeAsStringSync('PeptilogApp.build at ${DateTime.now().toIso8601String()}\n');
    } catch (_) {}
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
