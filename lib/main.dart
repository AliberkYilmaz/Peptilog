import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  // DIAGNOSTIC: per-stage breadcrumb log + 15s timeouts. Each step writes a
  // "STARTED" line before awaiting and "OK" after. On a hang, the last
  // "STARTED" line in peptilog-boot.txt identifies the culprit. A timeout
  // converts an infinite hang into a TimeoutException caught below.
  // Remove after root cause is fixed.
  String stage = 'pre-init';
  final breadcrumbs = StringBuffer(
    '=== Peptilog boot ${DateTime.now().toIso8601String()} ===\n',
  );

  Future<void> writeBreadcrumbs([String suffix = '']) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final content = '${breadcrumbs.toString()}$suffix';
      await File('${dir.path}/peptilog-boot.txt').writeAsString(content);
      // Also try public Downloads (may fail on API 29+ without MANAGE_EXTERNAL_STORAGE)
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        await File('${downloads.path}/peptilog-boot.txt').writeAsString(content);
      }
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
    await writeBreadcrumbs();
    try {
      final result = await body().timeout(
        timeout,
        onTimeout: () => throw TimeoutException('$name exceeded $timeout'),
      );
      final ms = DateTime.now().difference(t0).inMilliseconds;
      breadcrumbs.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] OK $name (${ms}ms)');
      await writeBreadcrumbs();
      return result;
    } catch (e) {
      breadcrumbs.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] FAILED $name: $e');
      await writeBreadcrumbs();
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
    await writeBreadcrumbs();

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
    await writeBreadcrumbs();
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
    _syncController = ref.read(syncControllerProvider);
    _syncController.init();

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
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
