import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../injection_log/domain/injection_log.dart';
import '../../../peptides/domain/peptide.dart';

/// The month currently focused in the calendar (normalized to first day).
final focusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// The currently selected day (null = nothing selected).
final selectedDayProvider = StateProvider<DateTime?>((ref) => null);

/// All injection logs mapped by normalized day key (year/month/day).
/// Sorted newest-first per day. Emits reactively via Isar watch.
final calendarEventsProvider =
    StreamProvider<Map<DateTime, List<InjectionLog>>>((ref) {
      final repo = ref.watch(injectionLogRepositoryProvider);
      return repo.watchAll().map((logs) {
        final Map<DateTime, List<InjectionLog>> result = {};
        for (final log in logs) {
          final key = DateTime(
            log.loggedAt.year,
            log.loggedAt.month,
            log.loggedAt.day,
          );
          result.putIfAbsent(key, () => []).add(log);
        }
        for (final list in result.values) {
          list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
        }
        return result;
      });
    });

/// Map of peptide id → Peptide for fast color/name lookup.
final peptideByIdProvider = StreamProvider<Map<int, Peptide>>((ref) {
  final repo = ref.watch(peptideRepositoryProvider);
  return repo.watchAll().map((list) => {for (final p in list) p.id: p});
});

/// Injection logs for the currently selected day (newest-first).
final selectedDayLogsProvider = Provider<List<InjectionLog>>((ref) {
  final selected = ref.watch(selectedDayProvider);
  if (selected == null) return const [];
  return ref
      .watch(calendarEventsProvider)
      .maybeWhen(
        data: (events) {
          final key = DateTime(selected.year, selected.month, selected.day);
          return events[key] ?? const [];
        },
        orElse: () => const [],
      );
});
