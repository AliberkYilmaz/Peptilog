import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../injection_log/domain/injection_log.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../../../weight/domain/weight_log.dart';

// ---------------------------------------------------------------------------
// Raw data providers
// ---------------------------------------------------------------------------

final _allInjectionsProvider = FutureProvider<List<InjectionLog>>((ref) async {
  return ref.watch(injectionLogRepositoryProvider).getAll();
});

final _allWeightLogsProvider = FutureProvider<List<WeightLog>>((ref) async {
  return ref.watch(weightLogRepositoryProvider).getAll();
});

// ---------------------------------------------------------------------------
// Streak analytics
// ---------------------------------------------------------------------------

class StreakData {
  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDaysLogged,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalDaysLogged;
}

final streakProvider = Provider<StreakData>((ref) {
  final injectionsAsync = ref.watch(_allInjectionsProvider);
  return injectionsAsync.maybeWhen(
    data: (logs) => _computeStreak(logs),
    orElse: () => const StreakData(
      currentStreak: 0,
      longestStreak: 0,
      totalDaysLogged: 0,
    ),
  );
});

StreakData _computeStreak(List<InjectionLog> logs) {
  if (logs.isEmpty) {
    return const StreakData(
      currentStreak: 0,
      longestStreak: 0,
      totalDaysLogged: 0,
    );
  }

  // Collect unique dates (ignoring time).
  final dates =
      logs
          .where((l) => !l.isDeleted)
          .map(
            (l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day),
          )
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));

  if (dates.isEmpty) {
    return const StreakData(
      currentStreak: 0,
      longestStreak: 0,
      totalDaysLogged: 0,
    );
  }

  int longest = 1;
  int current = 1;

  for (int i = 1; i < dates.length; i++) {
    final diff = dates[i].difference(dates[i - 1]).inDays;
    if (diff == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }

  // Check if the streak reaches today or yesterday (streak still alive).
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final lastDate = dates.last;
  final diffFromToday = todayDate.difference(lastDate).inDays;

  int activeStreak;
  if (diffFromToday <= 1) {
    // Streak is current — count backwards from last date.
    activeStreak = 1;
    for (int i = dates.length - 2; i >= 0; i--) {
      final diff = dates[i + 1].difference(dates[i]).inDays;
      if (diff == 1) {
        activeStreak++;
      } else {
        break;
      }
    }
  } else {
    activeStreak = 0;
  }

  return StreakData(
    currentStreak: activeStreak,
    longestStreak: longest,
    totalDaysLogged: dates.length,
  );
}

// ---------------------------------------------------------------------------
// Adherence analytics (last 30 days)
// ---------------------------------------------------------------------------

class AdherenceData {
  const AdherenceData({
    required this.actualDays,
    required this.expectedDays,
    required this.rate,
  });

  final int actualDays;
  final int expectedDays;
  final double rate;
}

final adherenceProvider = Provider<AdherenceData>((ref) {
  final injectionsAsync = ref.watch(_allInjectionsProvider);
  final remindersAsync = ref.watch(remindersProvider);

  final injections = injectionsAsync.valueOrNull ?? [];
  final reminders = remindersAsync.valueOrNull ?? [];

  return _computeAdherence(injections, reminders);
});

AdherenceData _computeAdherence(
  List<InjectionLog> injections,
  List<dynamic> reminders,
) {
  final now = DateTime.now();
  final cutoff = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 29));

  // Actual: unique days with at least one injection in last 30 days.
  final actualDays = injections
      .where((l) => !l.isDeleted && !l.loggedAt.isBefore(cutoff))
      .map((l) => DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day))
      .toSet()
      .length;

  // Expected: count days in last 30 where at least one active reminder fires.
  int expectedDays = 0;
  final activeReminders = reminders
      .where((r) => r.isActive && !r.isDeleted)
      .toList();

  if (activeReminders.isEmpty) {
    // No reminders → use actual as expected so rate shows 100%.
    return AdherenceData(
      actualDays: actualDays,
      expectedDays: actualDays,
      rate: actualDays == 0 ? 0.0 : 1.0,
    );
  }

  // For each day in last 30 days check if any reminder applies.
  for (int d = 0; d < 30; d++) {
    final day = cutoff.add(Duration(days: d));
    // ISO weekday: 1 = Monday, 7 = Sunday.
    final weekday = day.weekday;
    final anyFires = activeReminders.any((r) {
      final days = NotificationService.parseDays(r.daysOfWeek as String);
      return days.contains(weekday);
    });
    if (anyFires) expectedDays++;
  }

  final rate = expectedDays == 0
      ? 0.0
      : (actualDays / expectedDays).clamp(0.0, 1.0);

  return AdherenceData(
    actualDays: actualDays,
    expectedDays: expectedDays,
    rate: rate,
  );
}

// ---------------------------------------------------------------------------
// Correlation data: weight vs injection frequency (last 30 days)
// ---------------------------------------------------------------------------

class DayCorrelationPoint {
  const DayCorrelationPoint({
    required this.date,
    this.weightKg,
    required this.injectionCount,
  });

  final DateTime date;
  final double? weightKg;
  final int injectionCount;
}

final correlationProvider = Provider<List<DayCorrelationPoint>>((ref) {
  final injectionsAsync = ref.watch(_allInjectionsProvider);
  final weightAsync = ref.watch(_allWeightLogsProvider);

  final injections = injectionsAsync.valueOrNull ?? [];
  final weightLogs = weightAsync.valueOrNull ?? [];

  return _buildCorrelation(injections, weightLogs);
});

List<DayCorrelationPoint> _buildCorrelation(
  List<InjectionLog> injections,
  List<WeightLog> weightLogs,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final cutoff = today.subtract(const Duration(days: 29));

  // Map date → injection count.
  final injectionByDay = <DateTime, int>{};
  for (final log in injections) {
    if (log.isDeleted) continue;
    final d = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
    if (!d.isBefore(cutoff)) {
      injectionByDay[d] = (injectionByDay[d] ?? 0) + 1;
    }
  }

  // Map date → weight (most recent for that day).
  final weightByDay = <DateTime, double>{};
  for (final log in weightLogs) {
    if (log.isDeleted) continue;
    final d = DateTime(log.date.year, log.date.month, log.date.day);
    if (!d.isBefore(cutoff)) {
      weightByDay[d] = log.weightKg;
    }
  }

  // Build 30-day series.
  return List.generate(30, (i) {
    final date = cutoff.add(Duration(days: i));
    return DayCorrelationPoint(
      date: date,
      weightKg: weightByDay[date],
      injectionCount: injectionByDay[date] ?? 0,
    );
  });
}
