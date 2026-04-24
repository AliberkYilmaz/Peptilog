import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/quick_log_notifier.dart';
import '../widgets/peptide_selector.dart';

/// The body widget for the Quick Log tab.
///
/// Designed to be embedded in a Scaffold (no AppBar of its own).
/// After a successful save it shows a SnackBar and resets the form.
class QuickLogBody extends ConsumerStatefulWidget {
  const QuickLogBody({super.key});

  @override
  ConsumerState<QuickLogBody> createState() => _QuickLogBodyState();
}

class _QuickLogBodyState extends ConsumerState<QuickLogBody> {
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();
  final _doseFocus = FocusNode();

  @override
  void dispose() {
    _doseController.dispose();
    _notesController.dispose();
    _doseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for save completion to show SnackBar + reset.
    ref.listen<QuickLogState>(quickLogProvider, (prev, next) {
      if (!next.saved) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Injection logged'),
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reset controllers before notifier reset so they don't conflict.
      _doseController.clear();
      _notesController.clear();
      ref.read(quickLogProvider.notifier).reset();

      // Return to Calendar tab so the new dot appears immediately.
      ref.read(selectedTabProvider.notifier).state = 0;
    });

    final state = ref.watch(quickLogProvider);
    final notifier = ref.read(quickLogProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Peptide'),
          const SizedBox(height: 10),
          const PeptideSelector(),
          if (state.errorMessage == 'selectPeptide') ...[
            const SizedBox(height: 6),
            _ErrorText('Please select a peptide'),
          ],

          const SizedBox(height: 28),
          _SectionLabel('Dose'),
          const SizedBox(height: 10),
          _DoseField(
            controller: _doseController,
            focusNode: _doseFocus,
            onChanged: notifier.setDose,
            hasError: state.errorMessage == 'invalidDose',
          ),
          if (state.errorMessage == 'invalidDose') ...[
            const SizedBox(height: 6),
            _ErrorText('Enter a valid dose greater than zero'),
          ],

          const SizedBox(height: 28),
          _SectionLabel('Route'),
          const SizedBox(height: 10),
          _RouteToggle(selected: state.route, onChanged: notifier.setRoute),

          const SizedBox(height: 28),
          _SectionLabel('Notes'),
          const SizedBox(height: 10),
          _NotesField(
            controller: _notesController,
            onChanged: notifier.setNotes,
          ),

          const SizedBox(height: 28),
          _TimestampRow(
            loggedAt: state.loggedAt,
            onEdit: (dt) => notifier.setLoggedAt(dt),
          ),

          const SizedBox(height: 36),
          _SaveButton(
            isSaving: state.isSaving,
            onPressed: state.isSaving ? null : () => notifier.save(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppTheme.onSurface,
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(fontSize: 12, color: AppTheme.error),
    );
  }
}

class _DoseField extends StatelessWidget {
  const _DoseField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: const TextStyle(fontSize: 16, color: AppTheme.onBackground),
      decoration: InputDecoration(
        hintText: 'e.g. 0.5',
        hintStyle: TextStyle(color: AppTheme.onSurface.withAlpha(102)),
        suffixText: 'mg',
        suffixStyle: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? AppTheme.error : AppTheme.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _RouteToggle extends StatelessWidget {
  const _RouteToggle({required this.selected, required this.onChanged});

  final String selected;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['SubQ', 'IM'].map((route) {
        final isSelected = selected == route;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onChanged(route),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.amber : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppTheme.amber : AppTheme.divider,
                ),
              ),
              child: Text(
                route,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? const Color(0xFF1A1714)
                      : AppTheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 3,
      style: const TextStyle(fontSize: 15, color: AppTheme.onBackground),
      decoration: InputDecoration(
        hintText: 'Optional notes…',
        hintStyle: TextStyle(
          color: AppTheme.onSurface.withAlpha(102),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.amber, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({required this.loggedAt, required this.onEdit});

  final DateTime loggedAt;
  final void Function(DateTime) onEdit;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd MMM yyyy · HH:mm').format(loggedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: AppTheme.onSurface,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              formatted,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.onBackground,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _pickDateTime(context),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: loggedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppTheme.amber),
        ),
        child: child!,
      ),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(loggedAt),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppTheme.amber),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    onEdit(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A1714),
                ),
              )
            : const Text(
                'Save injection',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
