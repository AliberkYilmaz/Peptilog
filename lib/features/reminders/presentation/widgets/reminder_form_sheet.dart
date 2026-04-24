import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../peptides/domain/peptide.dart';
import '../../domain/reminder.dart';
import '../providers/reminder_providers.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _dayLabels = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

String _formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parseTime(String hhmm) {
  final parts = hhmm.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: parts.length > 1 ? int.parse(parts[1]) : 0,
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

/// Bottom sheet for creating or editing a [Reminder].
///
/// Pass [reminder] to edit an existing one; omit (or pass `null`) to create.
class ReminderFormSheet extends ConsumerStatefulWidget {
  const ReminderFormSheet({super.key, this.reminder});

  final Reminder? reminder;

  @override
  ConsumerState<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<ReminderFormSheet> {
  late int? _selectedPeptideId;
  late Set<int> _selectedDays;
  late TimeOfDay _time;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    if (r != null) {
      _selectedPeptideId = r.peptideId;
      _selectedDays = NotificationService.parseDays(r.daysOfWeek).toSet();
      _time = _parseTime(r.time);
      _isActive = r.isActive;
    } else {
      _selectedPeptideId = null;
      _selectedDays = {};
      _time = TimeOfDay.now();
      _isActive = true;
    }
  }

  bool get _isEditing => widget.reminder != null;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppTheme.surface,
            hourMinuteColor: AppTheme.background,
            dayPeriodColor: AppTheme.background,
            dialBackgroundColor: AppTheme.background,
            entryModeIconColor: AppTheme.amber,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_selectedPeptideId == null) {
      setState(() => _errorText = 'Select a peptide');
      return;
    }
    if (_selectedDays.isEmpty) {
      setState(() => _errorText = 'Select at least one day');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final repo = ref.read(reminderRepositoryProvider);
    final peptides = ref.read(activePeptidesProvider).valueOrNull ?? [];
    final peptide = peptides.firstWhere(
      (p) => p.id == _selectedPeptideId,
      orElse: () => peptides.first,
    );

    final reminder = widget.reminder ?? Reminder();
    reminder
      ..peptideId = _selectedPeptideId!
      ..daysOfWeek = _selectedDays
          .toList()
          .sorted()
          .map((d) => d.toString())
          .join(',')
      ..time = _formatTimeOfDay(_time)
      ..isActive = _isActive
      ..updatedAt = DateTime.now()
      ..isDirty = true;

    final savedId = await repo.save(reminder);
    reminder.id = savedId;

    // Request permission on first save if not already granted.
    final granted = await NotificationService.requestPermission();
    if (!granted && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            'Notifications disabled',
            style: GoogleFonts.playfairDisplay(color: AppTheme.onBackground),
          ),
          content: Text(
            "Enable notifications in Settings so Peptilog can remind you "
            "when it's time for your injection.",
            style: GoogleFonts.inter(color: AppTheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(color: AppTheme.amber),
              ),
            ),
          ],
        ),
      );
    }

    await NotificationService.scheduleReminder(reminder, peptide.name);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final reminder = widget.reminder!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Delete reminder?',
          style: GoogleFonts.playfairDisplay(color: AppTheme.onBackground),
        ),
        content: Text(
          'This reminder and its notifications will be removed.',
          style: GoogleFonts.inter(color: AppTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await NotificationService.cancelReminder(reminder.id);

    // Soft-delete so sync can propagate the deletion.
    reminder
      ..isDeleted = true
      ..updatedAt = DateTime.now()
      ..isDirty = true;
    await ref.read(reminderRepositoryProvider).save(reminder);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final peptidesAsync = ref.watch(activePeptidesProvider);
    final peptides = peptidesAsync.valueOrNull ?? <Peptide>[];
    final isLoading = peptidesAsync.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Handle bar ---
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Title ---
          Text(
            _isEditing ? 'Edit Reminder' : 'New Reminder',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.onBackground,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // --- Peptide selector ---
          Text(
            'Peptide',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(179),
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          if (isLoading)
            const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (peptides.isEmpty)
            Text(
              'No active peptides found. Add peptides first.',
              style: GoogleFonts.inter(
                color: AppTheme.onSurface.withAlpha(128),
                fontSize: 13,
              ),
            )
          else
            _PeptideDropdown(
              peptides: peptides,
              selectedId: _selectedPeptideId,
              onChanged: (id) => setState(() {
                _selectedPeptideId = id;
                _errorText = null;
              }),
            ),
          const SizedBox(height: 16),

          // --- Day-of-week chips ---
          Text(
            'Days',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(179),
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final day = i + 1;
              final label = _dayLabels[day]!;
              final selected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                    _errorText = null;
                  });
                },
                backgroundColor: AppTheme.background,
                selectedColor: AppTheme.amber.withAlpha(51),
                checkmarkColor: AppTheme.amber,
                labelStyle: GoogleFonts.inter(
                  color: selected ? AppTheme.amber : AppTheme.onSurface,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? AppTheme.amber : AppTheme.divider,
                ),
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // --- Time picker row ---
          Text(
            'Time',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(179),
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppTheme.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _time.format(context),
                    style: GoogleFonts.inter(
                      color: AppTheme.onBackground,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Active toggle ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active',
                style: GoogleFonts.inter(
                  color: AppTheme.onSurface,
                  fontSize: 14,
                ),
              ),
              Switch(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppTheme.amber,
                activeTrackColor: AppTheme.amber.withAlpha(102),
              ),
            ],
          ),

          // --- Error text ---
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: GoogleFonts.inter(color: AppTheme.error, fontSize: 12),
            ),
          ],

          const SizedBox(height: 20),

          // --- Action buttons ---
          FilledButton(
            onPressed: _isSaving || peptides.isEmpty ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1A1714),
                    ),
                  )
                : Text('Save', style: GoogleFonts.inter()),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _delete,
              child: Text(
                'Delete Reminder',
                style: GoogleFonts.inter(color: AppTheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Peptide dropdown
// ---------------------------------------------------------------------------

class _PeptideDropdown extends StatelessWidget {
  const _PeptideDropdown({
    required this.peptides,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Peptide> peptides;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          style: GoogleFonts.inter(color: AppTheme.onBackground, fontSize: 14),
          hint: Text(
            'Select peptide',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(128),
              fontSize: 14,
            ),
          ),
          items: peptides
              .map(
                (p) => DropdownMenuItem<int>(value: p.id, child: Text(p.name)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List sort extension (inline — avoids adding collection package)
// ---------------------------------------------------------------------------

extension _SortableList<T extends Comparable<T>> on List<T> {
  List<T> sorted() => [...this]..sort();
}
