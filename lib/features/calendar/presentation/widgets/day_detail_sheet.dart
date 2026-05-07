import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../injection_log/presentation/providers/quick_log_notifier.dart';
import '../providers/calendar_provider.dart';
import 'injection_log_tile.dart';

/// Bottom sheet showing all injection logs for [day], newest-first.
class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(selectedDayLogsProvider);
    final peptideMapAsync = ref.watch(peptideByIdProvider);
    final peptideMap = peptideMapAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <int, dynamic>{},
    );

    final dateLabel = DateFormat('EEEE, MMMM d').format(day);
    final countLabel = logs.isEmpty
        ? 'No injections'
        : logs.length == 1
        ? '1 injection'
        : '${logs.length} injections';

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: AppTheme.onBackground,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          countLabel,
                          style: TextStyle(
                            color: AppTheme.onSurface.withAlpha(153),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppTheme.onSurface,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: AppTheme.divider, height: 24),
            // Log list
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No injections logged',
                            style: TextStyle(
                              color: AppTheme.onSurface.withAlpha(128),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              final now = DateTime.now();
                              ref
                                  .read(quickLogProvider.notifier)
                                  .setLoggedAt(
                                    DateTime(
                                      day.year,
                                      day.month,
                                      day.day,
                                      now.hour,
                                      now.minute,
                                    ),
                                  );
                              ref.read(selectedTabProvider.notifier).state = 1;
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.amber,
                              foregroundColor: const Color(0xFF1A1714),
                            ),
                            child: const Text('Log Injection'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: logs.length,
                      separatorBuilder: (ctx, i) =>
                          Divider(color: AppTheme.divider, height: 1),
                      itemBuilder: (context, i) {
                        final log = logs[i];
                        return InjectionLogTile(
                          log: log,
                          peptide: peptideMap[log.peptideId],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
