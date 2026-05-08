import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/quick_log_notifier.dart';
import '../widgets/injection_form_widgets.dart';
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
          InjectionSectionLabel('Peptide'),
          const SizedBox(height: 10),
          const PeptideSelector(),
          if (state.errorMessage == 'selectPeptide') ...[
            const SizedBox(height: 6),
            InjectionErrorText('Please select a peptide'),
          ],

          const SizedBox(height: 28),
          InjectionSectionLabel('Dose'),
          const SizedBox(height: 10),
          InjectionDoseField(
            controller: _doseController,
            focusNode: _doseFocus,
            onChanged: notifier.setDose,
            hasError: state.errorMessage == 'invalidDose',
          ),
          if (state.errorMessage == 'invalidDose') ...[
            const SizedBox(height: 6),
            InjectionErrorText('Enter a valid dose greater than zero'),
          ],

          const SizedBox(height: 28),
          InjectionSectionLabel('Route'),
          const SizedBox(height: 10),
          InjectionRouteToggle(
            selected: state.route,
            onChanged: notifier.setRoute,
          ),

          const SizedBox(height: 28),
          InjectionSectionLabel('Notes'),
          const SizedBox(height: 10),
          InjectionNotesField(
            controller: _notesController,
            onChanged: notifier.setNotes,
          ),

          const SizedBox(height: 28),
          InjectionTimestampRow(
            loggedAt: state.loggedAt,
            onEdit: (dt) => notifier.setLoggedAt(dt),
          ),
          if (state.errorMessage == 'futureDate') ...[
            const SizedBox(height: 6),
            InjectionErrorText(
              'Logs are for past injections. Use Reminders to schedule ahead.',
            ),
          ],

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
