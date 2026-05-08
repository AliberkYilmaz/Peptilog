import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
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
import 'l10n/app_localizations.dart';

final Talker talker = TalkerFlutter.init(
  settings: TalkerSettings(useConsoleLogs: kDebugMode),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NDK native SDK disabled — it caused a JVM crash on boot (PEP-78).
  await SentryFlutter.init((options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 1.0;
    options.autoInitializeNativeSdk = false;
  });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    talker.handle(details.exception, details.stack, 'FlutterError caught');
    Sentry.captureException(details.exception, stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack, 'PlatformDispatcher.onError');
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };
  talker.info('Peptilog boot — version 1.0.20+20');

  await Firebase.initializeApp();

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
  final notificationLaunchRoute = await NotificationService.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: PeptilogApp(notificationLaunchRoute: notificationLaunchRoute),
    ),
  );
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
  StreamSubscription<Uri>? _deepLinkSub;
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();
    _syncController = ref.read(syncControllerProvider);
    _syncController.init();

    _appLinks = AppLinks();
    _deepLinkSub = _appLinks!.uriLinkStream.listen((uri) async {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e, st) {
        talker.warning('deep link: ignoring non-auth URI $uri', e, st);
      }
    });
    _appLinks!.getInitialLink().then((uri) async {
      if (uri != null) {
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
        } catch (e, st) {
          talker.warning('deep link initial: ignoring non-auth URI $uri', e, st);
        }
      }
    });

    _notifTapSub = NotificationService.tapRoute.listen((route) {
      final router = ref.read(appRouterProvider);
      router.go(route);
    });

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
    _deepLinkSub?.cancel();
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => TalkerWrapper(
        talker: talker,
        options: TalkerWrapperOptions(
          enableErrorAlerts: kDebugMode,
          enableExceptionAlerts: kDebugMode,
        ),
        child: kDebugMode
            ? Stack(children: [
                child!,
                Positioned(
                  right: 8,
                  bottom: 80,
                  child: SafeArea(
                    child: Builder(
                      builder: (innerContext) => FloatingActionButton.small(
                        heroTag: 'talker-debug-fab',
                        backgroundColor: AppTheme.amber,
                        foregroundColor: Colors.black,
                        onPressed: () {
                          final r = ref.read(appRouterProvider);
                          r.routerDelegate.navigatorKey.currentState?.push(
                            MaterialPageRoute<void>(
                              builder: (_) => TalkerScreen(talker: talker),
                            ),
                          );
                        },
                        child: const Icon(Icons.bug_report_outlined, size: 18),
                      ),
                    ),
                  ),
                ),
              ])
            : (child ?? const SizedBox.shrink()),
      ),
    );
  }
}
