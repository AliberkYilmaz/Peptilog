import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/weight_providers.dart';
import '../widgets/weight_chart.dart';
import '../widgets/weight_entry_form.dart';

/// Weight tab — tab index 2 in the main bottom nav.
///
/// Layout (top → bottom):
///   • Large current-weight display (Playfair Display serif)
///   • 30-day line chart (WeightChart)
///   • Goal weight chip / input row
///   • Weight entry form (WeightEntryForm)
class WeightBody extends ConsumerWidget {
  const WeightBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestWeightProvider);
    final goalKg = ref.watch(goalWeightProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current weight hero display
          _CurrentWeightDisplay(weightKg: latest?.weightKg),
          const SizedBox(height: 20),

          // 30-day chart
          const WeightChart(),
          const SizedBox(height: 12),

          // Goal weight row
          _GoalWeightRow(goalKg: goalKg),
          const SizedBox(height: 20),

          // Entry form
          const WeightEntryForm(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current weight display
// ---------------------------------------------------------------------------

class _CurrentWeightDisplay extends StatelessWidget {
  const _CurrentWeightDisplay({this.weightKg});

  final double? weightKg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Weight',
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(153),
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              weightKg != null ? weightKg!.toStringAsFixed(1) : '--',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.onBackground,
                fontSize: 52,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'kg',
              style: GoogleFonts.inter(
                color: AppTheme.onSurface.withAlpha(153),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Goal weight row
// ---------------------------------------------------------------------------

class _GoalWeightRow extends ConsumerStatefulWidget {
  const _GoalWeightRow({this.goalKg});

  final double? goalKg;

  @override
  ConsumerState<_GoalWeightRow> createState() => _GoalWeightRowState();
}

class _GoalWeightRowState extends ConsumerState<_GoalWeightRow> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return _editRow();
    }

    if (widget.goalKg == null) {
      return TextButton.icon(
        onPressed: () => setState(() {
          _editing = true;
          _controller.text = '';
        }),
        icon: const Icon(Icons.flag_outlined, size: 16, color: AppTheme.amber),
        label: Text(
          'Set goal weight',
          style: GoogleFonts.inter(color: AppTheme.amber, fontSize: 13),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
      );
    }

    return Row(
      children: [
        const Icon(Icons.flag, size: 14, color: AppTheme.amber),
        const SizedBox(width: 6),
        Text(
          'Goal: ${widget.goalKg!.toStringAsFixed(1)} kg',
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(179),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() {
            _editing = true;
            _controller.text = widget.goalKg!.toStringAsFixed(1);
          }),
          child: Text(
            'Edit',
            style: GoogleFonts.inter(
              color: AppTheme.amber,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => ref.read(goalWeightProvider.notifier).set(null),
          child: Text(
            'Remove',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(128),
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _editRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(color: AppTheme.onBackground),
            decoration: InputDecoration(
              hintText: 'Goal kg',
              hintStyle: GoogleFonts.inter(
                color: AppTheme.onSurface.withAlpha(102),
              ),
              suffixText: 'kg',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_controller.text.replaceAll(',', '.'));
            if (v != null && v > 0) {
              ref.read(goalWeightProvider.notifier).set(v);
              setState(() => _editing = false);
            }
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: Size.zero,
          ),
          child: Text('Set', style: GoogleFonts.inter()),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => setState(() => _editing = false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            minimumSize: Size.zero,
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: AppTheme.onSurface.withAlpha(153)),
          ),
        ),
      ],
    );
  }
}
