import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../injection_log/presentation/providers/quick_log_notifier.dart';
import '../peptides/domain/peptide.dart';
import 'calculator_logic.dart';

// ---------------------------------------------------------------------------
// Calculator screen
// ---------------------------------------------------------------------------

/// Peptide dosing calculator.
/// Route: /calculator
/// Accessible from Profile tab → Tools section.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  Peptide? _selectedPeptide;
  final _totalMgCtrl = TextEditingController();
  final _reconVolCtrl = TextEditingController();
  final _desiredDoseCtrl = TextEditingController();

  int? _resultUnits;
  String? _errorText;

  @override
  void dispose() {
    _totalMgCtrl.dispose();
    _reconVolCtrl.dispose();
    _desiredDoseCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final totalMg = double.tryParse(_totalMgCtrl.text.trim());
    final reconVol = double.tryParse(_reconVolCtrl.text.trim());
    final desiredDose = double.tryParse(_desiredDoseCtrl.text.trim());

    if (totalMg == null || totalMg <= 0) {
      setState(() {
        _resultUnits = null;
        _errorText = 'Total mg must be a positive number';
      });
      return;
    }
    if (reconVol == null || reconVol <= 0) {
      setState(() {
        _resultUnits = null;
        _errorText = 'Reconstitution volume must be a positive number';
      });
      return;
    }
    if (desiredDose == null || desiredDose <= 0) {
      setState(() {
        _resultUnits = null;
        _errorText = 'Desired dose must be a positive number';
      });
      return;
    }
    if (desiredDose > totalMg) {
      setState(() {
        _resultUnits = null;
        _errorText = 'Desired dose cannot exceed total mg in vial';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _resultUnits = calculateUnits(
        totalMg: totalMg,
        reconVolumeMl: reconVol,
        desiredDoseMg: desiredDose,
      );
    });
  }

  void _saveToLog() {
    if (_selectedPeptide == null || _resultUnits == null) return;
    final desiredDose = double.tryParse(_desiredDoseCtrl.text.trim());
    if (desiredDose == null) return;

    // Pre-fill Quick Log provider then navigate to the Log tab.
    final notifier = ref.read(quickLogProvider.notifier);
    notifier.selectPeptide(_selectedPeptide!);
    notifier.setDose(desiredDose.toStringAsFixed(2));

    context.go('/quick-log');
  }

  @override
  Widget build(BuildContext context) {
    final peptidesAsync = ref.watch(activePeptidesProvider);
    final peptides = peptidesAsync.valueOrNull ?? <Peptide>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Dose Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Peptide selector ---
            _SectionLabel('Peptide'),
            const SizedBox(height: 8),
            _PeptideDropdown(
              peptides: peptides,
              selected: _selectedPeptide,
              onChanged: (p) => setState(() => _selectedPeptide = p),
            ),
            const SizedBox(height: 20),

            // --- Numeric inputs ---
            _SectionLabel('Total mg in vial'),
            const SizedBox(height: 8),
            _NumericField(
              controller: _totalMgCtrl,
              hint: 'e.g. 5',
              onChanged: (_) => setState(() {
                _resultUnits = null;
                _errorText = null;
              }),
            ),
            const SizedBox(height: 16),

            _SectionLabel('Reconstitution volume (mL)'),
            const SizedBox(height: 8),
            _NumericField(
              controller: _reconVolCtrl,
              hint: 'e.g. 2',
              onChanged: (_) => setState(() {
                _resultUnits = null;
                _errorText = null;
              }),
            ),
            const SizedBox(height: 16),

            _SectionLabel('Desired dose (mg)'),
            const SizedBox(height: 8),
            _NumericField(
              controller: _desiredDoseCtrl,
              hint: 'e.g. 0.25',
              onChanged: (_) => setState(() {
                _resultUnits = null;
                _errorText = null;
              }),
            ),
            const SizedBox(height: 24),

            // --- Calculate button ---
            FilledButton(
              onPressed: _calculate,
              child: Text(
                'Calculate',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),

            // --- Error ---
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: GoogleFonts.inter(color: AppTheme.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            // --- Result card ---
            if (_resultUnits != null) ...[
              const SizedBox(height: 28),
              _ResultCard(units: _resultUnits!),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _selectedPeptide != null ? _saveToLog : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.amber.withAlpha(38),
                  foregroundColor: AppTheme.amber,
                ),
                child: Text(
                  'Save to Log',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              if (_selectedPeptide == null) ...[
                const SizedBox(height: 6),
                Text(
                  'Select a peptide to enable Save to Log',
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurface.withAlpha(128),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

            // --- Formula note ---
            const SizedBox(height: 32),
            Text(
              'Formula: Units = (Desired Dose ÷ Total mg) × (Recon Volume × 100)\n'
              'Rounded to nearest whole unit on a U-100 syringe.',
              style: GoogleFonts.inter(
                color: AppTheme.onSurface.withAlpha(102),
                fontSize: 11,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      text,
      style: GoogleFonts.inter(
        color: AppTheme.onSurface.withAlpha(179),
        fontSize: 12,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: onChanged,
      style: GoogleFonts.inter(color: AppTheme.onBackground, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppTheme.onSurface.withAlpha(102),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.amber),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _PeptideDropdown extends StatelessWidget {
  const _PeptideDropdown({
    required this.peptides,
    required this.selected,
    required this.onChanged,
  });

  final List<Peptide> peptides;
  final Peptide? selected;
  final ValueChanged<Peptide?> onChanged;

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
        child: DropdownButton<Peptide>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          style: GoogleFonts.inter(color: AppTheme.onBackground, fontSize: 14),
          hint: Text(
            'Select peptide (optional)',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(128),
              fontSize: 14,
            ),
          ),
          items: peptides
              .map(
                (p) => DropdownMenuItem<Peptide>(value: p, child: Text(p.name)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.units});
  final int units;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.amber.withAlpha(76)),
      ),
      child: Column(
        children: [
          Text(
            '$units',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.amber,
              fontSize: 64,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'units (U-100 syringe)',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(179),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
