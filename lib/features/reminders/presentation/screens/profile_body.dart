import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../peptides/domain/peptide.dart';
import '../../domain/reminder.dart';
import '../providers/reminder_providers.dart';
import '../widgets/reminder_form_sheet.dart';

// ---------------------------------------------------------------------------
// Day label map
// ---------------------------------------------------------------------------

const _dayAbbr = {
  1: 'Mo',
  2: 'Tu',
  3: 'We',
  4: 'Th',
  5: 'Fr',
  6: 'Sa',
  7: 'Su',
};

// ---------------------------------------------------------------------------
// Profile body
// ---------------------------------------------------------------------------

/// Profile tab — shows the user's injection reminders and account settings
/// stub. Reminders are the primary interactive section in this phase.
class ProfileBody extends ConsumerWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final peptidesAsync = ref.watch(activePeptidesProvider);

    final peptideList = peptidesAsync.valueOrNull ?? <Peptide>[];
    final peptideMap = <int, String>{
      for (final p in peptideList) p.id: p.name,
    };

    return remindersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error loading reminders',
          style: GoogleFonts.inter(color: AppTheme.error),
        ),
      ),
      data: (all) {
        final reminders = all.where((r) => !r.isDeleted).toList();

        if (reminders.isEmpty) {
          return _EmptyState(peptideMap: peptideMap);
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: reminders.length,
          separatorBuilder: (context, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return _ReminderCard(
              reminder: reminder,
              peptideName: peptideMap[reminder.peptideId] ?? 'Unknown',
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.peptideMap});

  final Map<int, String> peptideMap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 56,
            color: AppTheme.onSurface.withAlpha(76),
          ),
          const SizedBox(height: 12),
          Text(
            'No reminders yet',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.onSurface.withAlpha(153),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to schedule injection reminders',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(102),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reminder card
// ---------------------------------------------------------------------------

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({
    required this.reminder,
    required this.peptideName,
  });

  final Reminder reminder;
  final String peptideName;

  void _openEdit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReminderFormSheet(reminder: reminder),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = NotificationService.parseDays(reminder.daysOfWeek);
    final timeParts = reminder.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    final tod = TimeOfDay(hour: hour, minute: minute);

    return GestureDetector(
      onTap: () => _openEdit(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reminder.isActive ? AppTheme.divider : AppTheme.divider.withAlpha(128),
          ),
        ),
        child: Row(
          children: [
            // Left: peptide name + days + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        size: 14,
                        color: AppTheme.amber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        peptideName,
                        style: GoogleFonts.inter(
                          color: reminder.isActive
                              ? AppTheme.onBackground
                              : AppTheme.onSurface.withAlpha(128),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Day chips
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final active = days.contains(day);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.amber.withAlpha(38)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: active ? AppTheme.amber : AppTheme.divider,
                          ),
                        ),
                        child: Text(
                          _dayAbbr[day]!,
                          style: GoogleFonts.inter(
                            color: active
                                ? AppTheme.amber
                                : AppTheme.onSurface.withAlpha(76),
                            fontSize: 10,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tod.format(context),
                    style: GoogleFonts.inter(
                      color: AppTheme.onSurface.withAlpha(179),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Right: active indicator
            Icon(
              reminder.isActive
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: reminder.isActive
                  ? AppTheme.amber
                  : AppTheme.onSurface.withAlpha(76),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
