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
import 'core/sync/sync_controller.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  final isar = await IsarDatabase.open();
  await SeedService(isar).seedPresetsIfNeeded();

  final prefs = await SharedPreferences.getInstance();

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
        child: const PeptilogApp(),
      ),
    ),
  );
}

class PeptilogApp extends ConsumerStatefulWidget {
  const PeptilogApp({super.key});

  @override
  ConsumerState<PeptilogApp> createState() => _PeptilogAppState();
}

class _PeptilogAppState extends ConsumerState<PeptilogApp> {
  late SyncController _syncController;

  @override
  void initState() {
    super.initState();
    _syncController = ref.read(syncControllerProvider);
    _syncController.init();
  }

  @override
  void dispose() {
    _syncController.dispose();
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
