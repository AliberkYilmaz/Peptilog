import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../injection_log/domain/injection_log.dart';
import '../../../injection_log/presentation/providers/quick_log_notifier.dart';
import '../../../peptides/domain/peptide.dart';
import '../providers/calendar_provider.dart';
import 'edit_injection_sheet.dart';
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
      orElse: () => const <int, Peptide>{},
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
                              final selected = DateTime(
                                day.year,
                                day.month,
                                day.day,
                                now.hour,
                                now.minute,
                              );
                              final clamped =
                                  selected.isAfter(now) ? now : selected;
                              ref
                                  .read(quickLogProvider.notifier)
                                  .setLoggedAt(clamped);
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
                          onTap: () => _openEditSheet(
                            context,
                            log,
                            peptideMap[log.peptideId],
                          ),
                          onLongPress: () =>
                              _confirmQuickDelete(context, ref, log),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    InjectionLog log,
    Peptide? peptide,
  ) {
    return showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EditInjectionSheet(log: log, peptide: peptide),
    );
  }

  Future<void> _confirmQuickDelete(
    BuildContext context,
    WidgetRef ref,
    InjectionLog log,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.editInjectionDeleteConfirmTitle,
          style: const TextStyle(color: AppTheme.onBackground),
        ),
        content: Text(
          l10n.editInjectionDeleteConfirmBody,
          style: TextStyle(color: AppTheme.onSurface.withAlpha(179)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.editInjectionCancel,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.editInjectionDelete,
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(injectionLogRepositoryProvider).softDelete(log.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.editInjectionDeleted),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
