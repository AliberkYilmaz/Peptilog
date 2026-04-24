import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../peptides/domain/peptide.dart';
import '../injection_log/presentation/providers/quick_log_notifier.dart';
import 'order_calculator_logic.dart';

// ---------------------------------------------------------------------------
// Order Calculator screen
// ---------------------------------------------------------------------------

/// Vial order calculator.
/// Route: /order-calculator
/// Accessible from Profile tab → Tools section alongside Dose Calculator.
class OrderCalculatorScreen extends ConsumerStatefulWidget {
  const OrderCalculatorScreen({super.key});

  @override
  ConsumerState<OrderCalculatorScreen> createState() =>
      _OrderCalculatorScreenState();
}

class _OrderCalculatorScreenState
    extends ConsumerState<OrderCalculatorScreen> {
  Peptide? _selectedPeptide;
  final _doseCtrl = TextEditingController();
  final _injectionsCtrl = TextEditingController();
  final _weeksCtrl = TextEditingController();
  final _mgPerVialCtrl = TextEditingController();

  int? _resultVials;
  double? _totalMgNeeded;
  String? _errorText;

  @override
  void dispose() {
    _doseCtrl.dispose();
    _injectionsCtrl.dispose();
    _weeksCtrl.dispose();
    _mgPerVialCtrl.dispose();
    super.dispose();
  }

  void _clearResult() {
    _resultVials = null;
    _totalMgNeeded = null;
    _errorText = null;
  }

  void _calculate() {
    final dose = double.tryParse(_doseCtrl.text.trim());
    final injections = double.tryParse(_injectionsCtrl.text.trim());
    final weeks = double.tryParse(_weeksCtrl.text.trim());
    final mgPerVial = double.tryParse(_mgPerVialCtrl.text.trim());

    if (dose == null || dose <= 0) {
      setState(() {
        _clearResult();
        _errorText = 'Dose per injection must be a positive number';
      });
      return;
    }
    if (injections == null || injections <= 0) {
      setState(() {
        _clearResult();
        _errorText = 'Injections per week must be a positive number';
      });
      return;
    }
    if (weeks == null || weeks <= 0) {
      setState(() {
        _clearResult();
        _errorText = 'Weeks of supply must be a positive number';
      });
      return;
    }
    if (mgPerVial == null || mgPerVial <= 0) {
      setState(() {
        _clearResult();
        _errorText = 'mg per vial must be a positive number';
      });
      return;
    }

    final total = dose * injections * weeks;
    final vials = calculateVialsNeeded(
      dosePerInjectionMg: dose,
      injectionsPerWeek: injections,
      weeksOfSupply: weeks,
      mgPerVial: mgPerVial,
    );

    setState(() {
      _errorText = null;
      _totalMgNeeded = total;
      _resultVials = vials;
    });
  }

  @override
  Widget build(BuildContext context) {
    final peptidesAsync = ref.watch(activePeptidesProvider);
    final peptides = peptidesAsync.valueOrNull ?? <Peptide>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Order Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Peptide selector (optional) ---
            _SectionLabel('Peptide (optional)'),
            const SizedBox(height: 8),
            _PeptideDropdown(
              peptides: peptides,
              selected: _selectedPeptide,
              onChanged: (p) => setState(() => _selectedPeptide = p),
            ),
            const SizedBox(height: 20),

            // --- Dose per injection ---
            _SectionLabel('Dose per injection (mg)'),
            const SizedBox(height: 8),
            _NumericField(
              controller: _doseCtrl,
              hint: 'e.g. 0.5',
              onChanged: (_) => setState(_clearResult),
            ),
            const SizedBox(height: 16),

            // --- Injections per week ---
            _SectionLabel('Injections per week'),
            const SizedBox(height: 8),
            _NumericField(
              controller: _injectionsCtrl,
              hint: 'e.g. 3',
              onChanged: (_) => setState(_clearResult),
            ),
            const SizedBox(height: 16),

            // --- Weeks of supply ---
            _SectionLabel('Weeks of supply'),
            const SizedBox(height: 8),
            _NumericField(
              controller: _weeksCtrl,
              hint: 'e.g. 12',
              onChanged: (_) => setState(_clearResult),
            ),
            const SizedBox(height: 16),

            // --- mg per vial ---
            _SectionLabel('mg per vial'),
            const SizedBox(height: 8),
            _NumericField(
              controller: _mgPerVialCtrl,
              hint: 'e.g. 5',
              onChanged: (_) => setState(_clearResult),
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
            if (_resultVials != null && _totalMgNeeded != null) ...[
              const SizedBox(height: 28),
              _ResultCard(
                vials: _resultVials!,
                totalMg: _totalMgNeeded!,
              ),
            ],

            // --- Formula note ---
            const SizedBox(height: 32),
            Text(
              'Formula: Total mg = dose × injections/week × weeks\n'
              'Vials needed = ⌈ total mg ÷ mg per vial ⌉ (always rounds up)',
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
  const _ResultCard({required this.vials, required this.totalMg});

  final int vials;
  final double totalMg;

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
            '$vials',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.amber,
              fontSize: 64,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vials == 1 ? 'vial needed' : 'vials needed',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(179),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total: ${totalMg.toStringAsFixed(2)} mg',
              style: GoogleFonts.inter(
                color: AppTheme.onSurface.withAlpha(179),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
