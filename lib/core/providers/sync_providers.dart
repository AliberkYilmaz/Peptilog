import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_providers.dart';
import '../../features/health/data/supabase_blood_pressure_log_repository.dart';
import '../../features/health/data/supabase_sleep_log_repository.dart';
import '../../features/injection_log/data/supabase_injection_log_repository.dart';
import '../../features/peptides/data/supabase_peptide_repository.dart';
import '../../features/reminders/data/supabase_reminder_repository.dart';
import '../../features/weight/data/supabase_weight_log_repository.dart';
import '../sync/sync_controller.dart';
import '../sync/sync_service.dart';
import 'connectivity_providers.dart';
import 'database_providers.dart';

/// SharedPreferences instance — must be overridden in ProviderScope after init.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope after init',
  );
});

final _supabaseInjectionLogRepoProvider =
    Provider<SupabaseInjectionLogRepository>(
      (ref) =>
          SupabaseInjectionLogRepository(ref.watch(supabaseClientProvider)),
    );

final _supabasePeptideRepoProvider = Provider<SupabasePeptideRepository>(
  (ref) => SupabasePeptideRepository(ref.watch(supabaseClientProvider)),
);

final _supabaseWeightLogRepoProvider = Provider<SupabaseWeightLogRepository>(
  (ref) => SupabaseWeightLogRepository(ref.watch(supabaseClientProvider)),
);

final _supabaseSleepLogRepoProvider = Provider<SupabaseSleepLogRepository>(
  (ref) => SupabaseSleepLogRepository(ref.watch(supabaseClientProvider)),
);

final _supabaseBloodPressureLogRepoProvider =
    Provider<SupabaseBloodPressureLogRepository>(
      (ref) =>
          SupabaseBloodPressureLogRepository(ref.watch(supabaseClientProvider)),
    );

final _supabaseReminderRepoProvider = Provider<SupabaseReminderRepository>(
  (ref) => SupabaseReminderRepository(ref.watch(supabaseClientProvider)),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return SyncService(
    isar: ref.watch(isarProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    injectionLogRepo: ref.watch(_supabaseInjectionLogRepoProvider),
    peptideRepo: ref.watch(_supabasePeptideRepoProvider),
    weightLogRepo: ref.watch(_supabaseWeightLogRepoProvider),
    sleepLogRepo: ref.watch(_supabaseSleepLogRepoProvider),
    bloodPressureLogRepo: ref.watch(_supabaseBloodPressureLogRepoProvider),
    reminderRepo: ref.watch(_supabaseReminderRepoProvider),
    checkConnectivity: () => connectivityService.isOnline,
  );
});

final syncControllerProvider = Provider<SyncController>((ref) {
  final service = ref.watch(syncServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  return SyncController(
    syncService: service,
    onlineStream: connectivityService.onlineStream,
  );
});
