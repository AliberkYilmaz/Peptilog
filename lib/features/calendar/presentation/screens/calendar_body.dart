import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../injection_log/domain/injection_log.dart';
import '../providers/calendar_provider.dart';
import '../widgets/day_detail_sheet.dart';

/// Calendar tab body — month view with colored injection dots.
///
/// Spec: §3.1, §4.1, §5 — month view, dot markers per peptide per day,
/// tap-to-detail sheet, swipe between months.
class CalendarBody extends ConsumerWidget {
  const CalendarBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final peptideMapAsync = ref.watch(peptideByIdProvider);

    final events = eventsAsync.maybeWhen(
      data: (e) => e,
      orElse: () => const <DateTime, List<InjectionLog>>{},
    );
    final peptideMap = peptideMapAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <int, dynamic>{},
    );

    return TableCalendar<InjectionLog>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedMonth,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        return events[key] ?? const [];
      },
      onDaySelected: (selected, focused) {
        ref.read(selectedDayProvider.notifier).state = selected;
        ref.read(focusedMonthProvider.notifier).state = DateTime(
          focused.year,
          focused.month,
        );
        _showDayDetail(context, ref, selected);
      },
      onPageChanged: (focused) {
        ref.read(focusedMonthProvider.notifier).state = DateTime(
          focused.year,
          focused.month,
        );
        // Clear selection when month changes.
        ref.read(selectedDayProvider.notifier).state = null;
      },
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppTheme.amber.withAlpha(51),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(color: AppTheme.amber),
        selectedDecoration: const BoxDecoration(
          color: AppTheme.amber,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Color(0xFF1A1714)),
        defaultTextStyle: const TextStyle(color: AppTheme.onSurface),
        weekendTextStyle: const TextStyle(color: AppTheme.onSurface),
        outsideTextStyle: TextStyle(color: AppTheme.onSurface.withAlpha(76)),
        markersMaxCount: 0, // We render our own markers.
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: const TextStyle(
          color: AppTheme.onBackground,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          color: AppTheme.onBackground,
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          color: AppTheme.onBackground,
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: AppTheme.onSurface.withAlpha(153),
          fontSize: 12,
        ),
        weekendStyle: TextStyle(
          color: AppTheme.onSurface.withAlpha(153),
          fontSize: 12,
        ),
      ),
      calendarBuilders: CalendarBuilders<InjectionLog>(
        markerBuilder: (context, day, dayEvents) {
          if (dayEvents.isEmpty) return null;

          // Show one dot per unique peptide, capped at 4.
          final seenIds = <int>{};
          final uniqueLogs = dayEvents
              .where((log) => seenIds.add(log.peptideId))
              .take(4);

          return Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: uniqueLogs.map((log) {
                Color dotColor = AppTheme.amber;
                final peptide = peptideMap[log.peptideId];
                if (peptide != null) {
                  dotColor = _parseHex(peptide.color);
                }
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showDayDetail(BuildContext context, WidgetRef ref, DateTime day) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: DayDetailSheet(day: day),
      ),
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    }
    return AppTheme.amber;
  }
}
