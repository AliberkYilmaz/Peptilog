import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/health_providers.dart';

/// Sleep entry form: hours input, optional quality rating, date picker.
class SleepEntryForm extends ConsumerWidget {
  const SleepEntryForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepFormProvider);
    final notifier = ref.read(sleepFormProvider.notifier);

    ref.listen<SleepFormState>(sleepFormProvider, (_, next) {
      if (next.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sleep saved',
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
            'Log Sleep',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Hours input
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
                    hintText: '7.5',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.onSurface.withAlpha(102),
                    ),
                    suffixText: 'h',
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
                  onChanged: notifier.setHours,
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
          // Quality rating
          _QualityRating(
            value: state.qualityRating,
            onChanged: notifier.setQuality,
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
    'invalidHours' => 'Enter valid hours (0.5–24)',
    _ => null,
  };
}

class _QualityRating extends StatelessWidget {
  const _QualityRating({this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Quality',
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(153),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(5, (i) {
          final star = i + 1;
          final filled = value != null && star <= value!;
          return GestureDetector(
            onTap: () => onChanged(star),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 24,
                color: filled
                    ? AppTheme.amber
                    : AppTheme.onSurface.withAlpha(102),
              ),
            ),
          );
        }),
        if (value != null) ...[
          const SizedBox(width: 8),
          Text(
            '$value/5',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(153),
              fontSize: 12,
            ),
          ),
        ],
      ],
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
