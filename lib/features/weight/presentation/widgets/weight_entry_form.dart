import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/weight_providers.dart';

/// Weight entry form: kg input, date picker, save to Isar.
/// One entry per day enforced by the notifier.
class WeightEntryForm extends ConsumerWidget {
  const WeightEntryForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weightFormProvider);
    final notifier = ref.read(weightFormProvider.notifier);

    // Pop-up snackbar on successful save.
    ref.listen<WeightFormState>(weightFormProvider, (_, next) {
      if (next.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Weight saved',
              style: GoogleFonts.inter(color: AppTheme.background),
            ),
            backgroundColor: AppTheme.amber,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        notifier.reset();
      }
    });

    final errorText = _errorText(state.errorMessage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Log Weight',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // kg input
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: GoogleFonts.inter(color: AppTheme.onBackground),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.onSurface.withAlpha(102),
                    ),
                    suffixText: 'kg',
                    suffixStyle: GoogleFonts.inter(
                      color: AppTheme.onSurface.withAlpha(153),
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorText,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: notifier.setWeight,
                ),
              ),
              const SizedBox(width: 12),
              // Date picker
              Expanded(
                flex: 3,
                child: _DatePickerButton(
                  date: state.effectiveDate,
                  onPick: notifier.setDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.isSaving ? null : notifier.save,
            child: state.isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.background,
                    ),
                  )
                : Text('Save', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  String? _errorText(String? code) => switch (code) {
    'invalidWeight' => 'Enter a valid weight (e.g. 75.5)',
    'duplicateDate' => 'Entry already exists for this date',
    _ => null,
  };
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({required this.date, required this.onPick});

  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.amber,
                onPrimary: Color(0xFF1A1714),
                surface: AppTheme.surface,
                onSurface: AppTheme.onBackground,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.amber,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('MMM d, y').format(date),
                style: GoogleFonts.inter(
                  color: AppTheme.onBackground,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
