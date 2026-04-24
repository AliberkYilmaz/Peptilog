import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/health_providers.dart';

/// Blood pressure entry form: systolic, diastolic, optional pulse, date/time.
class BloodPressureEntryForm extends ConsumerWidget {
  const BloodPressureEntryForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bpFormProvider);
    final notifier = ref.read(bpFormProvider.notifier);

    ref.listen<BpFormState>(bpFormProvider, (_, next) {
      if (next.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reading saved',
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
            'Log Reading',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Systolic / Diastolic row
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  hintText: '120',
                  labelText: 'Systolic',
                  suffixText: 'mmHg',
                  errorText: state.errorMessage == 'invalidSystolic'
                      ? errorText
                      : null,
                  onChanged: notifier.setSystolic,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.onSurface.withAlpha(153),
                    fontSize: 22,
                  ),
                ),
              ),
              Expanded(
                child: _NumberField(
                  hintText: '80',
                  labelText: 'Diastolic',
                  suffixText: 'mmHg',
                  errorText: state.errorMessage == 'invalidDiastolic'
                      ? errorText
                      : null,
                  onChanged: notifier.setDiastolic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pulse + date row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _NumberField(
                  hintText: '72',
                  labelText: 'Pulse (optional)',
                  suffixText: 'bpm',
                  onChanged: notifier.setPulse,
                ),
              ),
              const SizedBox(width: 12),
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
    'invalidSystolic' => 'Enter valid systolic (60–250)',
    'invalidDiastolic' => 'Enter valid diastolic (40–150)',
    _ => null,
  };
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.hintText,
    required this.labelText,
    required this.onChanged,
    this.suffixText,
    this.errorText,
  });

  final String hintText;
  final String labelText;
  final String? suffixText;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.inter(color: AppTheme.onBackground),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.inter(
          color: AppTheme.onSurface.withAlpha(153),
          fontSize: 11,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: AppTheme.onSurface.withAlpha(102)),
        suffixText: suffixText,
        suffixStyle: GoogleFonts.inter(
          color: AppTheme.onSurface.withAlpha(153),
          fontSize: 11,
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
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
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
                DateFormat('MMM d').format(date),
                style: GoogleFonts.inter(
                  color: AppTheme.onBackground,
                  fontSize: 13,
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
