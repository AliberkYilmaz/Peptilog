import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

/// Section label used in both Quick Log and Edit Injection forms.
class InjectionSectionLabel extends StatelessWidget {
  const InjectionSectionLabel(this.text, {super.key});

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

/// Inline validation error text for injection forms.
class InjectionErrorText extends StatelessWidget {
  const InjectionErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(fontSize: 12, color: AppTheme.error),
    );
  }
}

/// Numeric dose text field with 'mg' suffix, shared across injection forms.
class InjectionDoseField extends StatelessWidget {
  const InjectionDoseField({
    super.key,
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

/// SubQ / IM toggle shared across injection forms.
class InjectionRouteToggle extends StatelessWidget {
  const InjectionRouteToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

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

/// Multi-line notes textarea shared across injection forms.
class InjectionNotesField extends StatelessWidget {
  const InjectionNotesField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

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

/// Timestamp display row with an inline Edit tap shared across injection forms.
class InjectionTimestampRow extends StatelessWidget {
  const InjectionTimestampRow({
    super.key,
    required this.loggedAt,
    required this.onEdit,
  });

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
