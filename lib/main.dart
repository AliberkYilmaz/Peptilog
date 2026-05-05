import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  // DIAGNOSTIC BUILD — staged try/catch so boot failures show the exact failing
  // stage + exception on-screen instead of a silent OS crash dialog. Remove
  // once the crash root-cause is identified and fixed.
  String stage = 'pre-init';
  try {
    stage = 'Firebase.initializeApp';
    await Firebase.initializeApp();

    stage = 'Supabase.initialize';
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );

    stage = 'IsarDatabase.open';
    final isar = await IsarDatabase.open();

    stage = 'SeedService.seedPresetsIfNeeded';
    await SeedService(isar).seedPresetsIfNeeded();

    stage = 'NotificationService.initialize';
    final notificationLaunchRoute = await NotificationService.initialize();

    stage = 'SharedPreferences.getInstance';
    final prefs = await SharedPreferences.getInstance();

    stage = 'SentryFlutter.init';
    await SentryFlutter.init(
      (options) {
        options.dsn = const String.fromEnvironment('SENTRY_DSN');
        options.environment = const String.fromEnvironment(
          'ENV',
          defaultValue: 'development',
        );
      },
      appRunner: () => runApp(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(isar),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: PeptilogApp(notificationLaunchRoute: notificationLaunchRoute),
        ),
      ),
    );
  } catch (e, st) {
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
                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'STAGE: $stage',
                    style: const TextStyle(color: Colors.amber, fontSize: 14, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  const Text('ERROR:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '$e',
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Text('STACK:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '$st',
                    style: const TextStyle(color: Colors.white60, fontFamily: 'monospace', fontSize: 10),
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
