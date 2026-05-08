import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:peptilog_app/main.dart' show talker;
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/services/export_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_providers.dart';
import '../../../auth/data/biometric_repository.dart';
import '../../../auth/data/pin_repository.dart';
import '../../../auth/presentation/providers/pin_notifier.dart';
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
// Providers
// ---------------------------------------------------------------------------

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

final _biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricRepositoryProvider).isAvailable(),
);

final _biometricEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(pinRepositoryProvider).isBiometricEnabled(),
);

// ---------------------------------------------------------------------------
// Profile body
// ---------------------------------------------------------------------------

class ProfileBody extends ConsumerWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final remindersAsync = ref.watch(remindersProvider);
    final peptidesAsync = ref.watch(activePeptidesProvider);
    final appVersionAsync = ref.watch(_appVersionProvider);
    final biometricAvailableAsync = ref.watch(_biometricAvailableProvider);
    final biometricEnabledAsync = ref.watch(_biometricEnabledProvider);

    final user = authAsync.valueOrNull;
    final peptideList = peptidesAsync.valueOrNull ?? <Peptide>[];
    final peptideMap = <int, String>{for (final p in peptideList) p.id: p.name};
    final reminders = (remindersAsync.valueOrNull ?? <Reminder>[])
        .where((r) => !r.isDeleted)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // ── Account ─────────────────────────────────────────────────────────
        _SectionHeader('Account'),
        const SizedBox(height: 8),
        _InfoTile(
          icon: Icons.person_outline,
          label: user?.displayName ?? user?.email ?? 'Signed in',
          subtitle: (user?.displayName != null) ? user!.email : null,
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.logout,
          label: 'Sign Out',
          onTap: () => _confirmSignOut(context, ref),
        ),
        const SizedBox(height: 24),

        // ── Security ────────────────────────────────────────────────────────
        _SectionHeader('Security'),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.lock_outline,
          label: 'Change PIN',
          onTap: () => context.push('/auth/pin-change'),
        ),
        const SizedBox(height: 8),
        biometricAvailableAsync.maybeWhen(
          data: (available) {
            if (!available) return const SizedBox.shrink();
            return biometricEnabledAsync.maybeWhen(
              data: (enabled) => _SwitchTile(
                icon: Icons.fingerprint,
                label: 'Face ID / Touch ID',
                value: enabled,
                onChanged: (v) async {
                  await ref
                      .read(pinRepositoryProvider)
                      .setBiometricEnabled(enabled: v);
                  ref.invalidate(_biometricEnabledProvider);
                },
              ),
              orElse: () => const SizedBox.shrink(),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // ── Tools ───────────────────────────────────────────────────────────
        _SectionHeader('Tools'),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.calculate_outlined,
          label: 'Dose Calculator',
          onTap: () => context.push('/calculator'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.inventory_2_outlined,
          label: 'Order Calculator',
          onTap: () => context.push('/order-calculator'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.bar_chart_outlined,
          label: 'Analytics',
          onTap: () => context.push('/analytics'),
        ),
        const SizedBox(height: 24),

        // ── Reminders ───────────────────────────────────────────────────────
        _SectionHeader('Reminders'),
        const SizedBox(height: 8),
        if (reminders.isEmpty)
          const _EmptyRemindersHint()
        else
          ...reminders.asMap().entries.map((entry) {
            final i = entry.key;
            final reminder = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: _ReminderCard(
                reminder: reminder,
                peptideName: peptideMap[reminder.peptideId] ?? 'Unknown',
              ),
            );
          }),
        const SizedBox(height: 24),

        // ── Data ────────────────────────────────────────────────────────────
        _SectionHeader('Data'),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.file_download_outlined,
          label: 'Export All Data (CSV)',
          onTap: () => _export(context, ref, null),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.colorize_outlined,
          label: 'Export Injections',
          onTap: () => _export(context, ref, 'injections'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.monitor_weight_outlined,
          label: 'Export Weight',
          onTap: () => _export(context, ref, 'weight'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.bedtime_outlined,
          label: 'Export Sleep',
          onTap: () => _export(context, ref, 'sleep'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.favorite_border,
          label: 'Export Blood Pressure',
          onTap: () => _export(context, ref, 'bp'),
        ),
        const SizedBox(height: 16),
        _ActionTile(
          icon: Icons.delete_forever_outlined,
          label: 'Delete Account',
          labelColor: AppTheme.error,
          iconColor: AppTheme.error,
          onTap: () => _confirmDeleteAccount(context, ref),
        ),
        const SizedBox(height: 24),

        // ── About ───────────────────────────────────────────────────────────
        _SectionHeader('About'),
        const SizedBox(height: 8),
        _VersionTile(version: appVersionAsync.valueOrNull ?? '…'),
        const SizedBox(height: 8),
        const _InfoTile(
          icon: Icons.medical_services_outlined,
          label: 'Medical Disclaimer',
          subtitle:
              'Peptilog is a personal health tracking tool. It does not provide'
              ' medical advice. Always consult a qualified healthcare provider'
              ' before using any peptide or supplement.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Sign Out',
          style: GoogleFonts.playfairDisplay(color: AppTheme.onBackground),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authRepositoryProvider).signOut();
    ref.read(pinVerifiedProvider.notifier).state = false;
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String? type,
  ) async {
    final svc = ref.read(exportServiceProvider);
    try {
      switch (type) {
        case null:
          await svc.exportAll();
        case 'injections':
          await svc.exportInjections();
        case 'weight':
          await svc.exportWeight();
        case 'sleep':
          await svc.exportSleep();
        case 'bp':
          await svc.exportBloodPressure();
      }
    } catch (e, st) {
      talker.handle(e, st, 'export.$type');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Delete Account',
          style: GoogleFonts.playfairDisplay(color: AppTheme.error),
        ),
        content: Text(
          'This will permanently delete all your data — injections, weight,'
          ' sleep, blood pressure logs, reminders, and your account.\n\n'
          'This cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.onSurface),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (ok1 != true || !context.mounted) return;

    final ok2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Final Confirmation',
          style: GoogleFonts.playfairDisplay(color: AppTheme.error),
        ),
        content: Text(
          'All data will be deleted immediately and cannot be recovered.',
          style: GoogleFonts.inter(color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.onSurface),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (ok2 != true || !context.mounted) return;

    // Progress indicator
    if (context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          backgroundColor: AppTheme.surface,
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account…'),
            ],
          ),
        ),
      );
    }

    try {
      // 1. Wipe all local Isar collections via ExportService
      await ref.read(exportServiceProvider).deleteAllLocalData();

      // 2. Clear secure storage (PIN + biometric flags)
      final pinRepo = ref.read(pinRepositoryProvider);
      await pinRepo.clearPin();
      await pinRepo.setBiometricEnabled(enabled: false);

      // 3. Delete Supabase auth account (edge function + sign out)
      await ref.read(authRepositoryProvider).deleteAccount();

      // 4. Reset local auth state
      ref.read(pinVerifiedProvider.notifier).state = false;
    } catch (e, st) {
      talker.handle(e, st, 'deleteAccount');
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppTheme.onSurface.withAlpha(128),
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info tile (read-only)
// ---------------------------------------------------------------------------

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, this.subtitle});

  final IconData icon;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppTheme.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      color: AppTheme.onSurface.withAlpha(153),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Version tile (7-tap to open Talker)
// ---------------------------------------------------------------------------

class _VersionTile extends StatefulWidget {
  const _VersionTile({required this.version});
  final String version;

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  int _tapCount = 0;
  Timer? _resetTimer;

  static const _requiredTaps = 7;
  static const _hintStartAt = 4;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _resetTimer?.cancel();
    _tapCount++;

    if (_tapCount >= _requiredTaps) {
      _tapCount = 0;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TalkerScreen(talker: talker),
        ),
      );
      return;
    }

    if (_tapCount >= _hintStartAt) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            'Debug mode in ${_requiredTaps - _tapCount} taps',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ));
    }

    _resetTimer = Timer(const Duration(seconds: 3), () => _tapCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: _InfoTile(
        icon: Icons.info_outline,
        label: 'Version',
        subtitle: widget.version,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action tile (tappable)
// ---------------------------------------------------------------------------

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppTheme.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: labelColor ?? AppTheme.onBackground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.onSurface.withAlpha(102),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Switch tile
// ---------------------------------------------------------------------------

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.onBackground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.amber,
            activeTrackColor: AppTheme.amber.withAlpha(102),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty reminders hint
// ---------------------------------------------------------------------------

class _EmptyRemindersHint extends StatelessWidget {
  const _EmptyRemindersHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 18,
            color: AppTheme.onSurface.withAlpha(76),
          ),
          const SizedBox(width: 8),
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
  const _ReminderCard({required this.reminder, required this.peptideName});

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
            color: reminder.isActive
                ? AppTheme.divider
                : AppTheme.divider.withAlpha(128),
          ),
        ),
        child: Row(
          children: [
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
