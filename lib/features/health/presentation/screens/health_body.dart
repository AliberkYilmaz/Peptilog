import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/blood_pressure_log.dart';
import '../../domain/sleep_log.dart';
import '../providers/health_providers.dart';
import '../widgets/blood_pressure_chart.dart';
import '../widgets/blood_pressure_entry_form.dart';
import '../widgets/sleep_chart.dart';
import '../widgets/sleep_entry_form.dart';

/// Health tab — tab index 3 in the main bottom nav.
///
/// Layout:
///   • SegmentedButton: Sleep | Blood Pressure
///   • Sleep section (tab 0): hero hours display, 30-day chart, entry form
///   • Blood Pressure section (tab 1): hero SYS/DIA display, 30-day chart, entry form
class HealthBody extends ConsumerWidget {
  const HealthBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedTab = ref.watch(selectedHealthTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Segmented control ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                label: Text(l10n.healthTabSleep),
                icon: const Icon(Icons.bedtime_outlined, size: 16),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text(l10n.healthTabBloodPressure),
                icon: const Icon(Icons.favorite_outline, size: 16),
              ),
            ],
            selected: {selectedTab},
            onSelectionChanged: (Set<int> newSelection) {
              ref.read(selectedHealthTabProvider.notifier).state =
                  newSelection.first;
            },
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),

        // ── Tab content ─────────────────────────────────────────────────────
        Expanded(
          child: IndexedStack(
            index: selectedTab,
            children: const [_SleepSection(), _BloodPressureSection()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep section
// ---------------------------------------------------------------------------

class _SleepSection extends ConsumerWidget {
  const _SleepSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SleepLog? latest = ref.watch(latestSleepProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SleepHeroDisplay(latest: latest),
          const SizedBox(height: 16),
          const SleepChart(),
          const SizedBox(height: 8),
          _ChartLegend(
            items: const [
              _LegendItem(color: AppTheme.amber, label: 'Hours slept'),
            ],
          ),
          const SizedBox(height: 16),
          const SleepEntryForm(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SleepHeroDisplay extends StatelessWidget {
  const _SleepHeroDisplay({this.latest});

  final SleepLog? latest;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          latest != null ? latest!.hours.toStringAsFixed(1) : '--',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.onBackground,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'h',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(153),
              fontSize: 18,
            ),
          ),
        ),
        if (latest?.qualityRating != null) ...[
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: List.generate(5, (i) {
                final filled = (i + 1) <= latest!.qualityRating!;
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: filled
                      ? AppTheme.amber
                      : AppTheme.onSurface.withAlpha(76),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Blood Pressure section
// ---------------------------------------------------------------------------

class _BloodPressureSection extends ConsumerWidget {
  const _BloodPressureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BloodPressureLog? latest = ref.watch(latestBloodPressureProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BpHeroDisplay(latest: latest),
          const SizedBox(height: 16),
          const BloodPressureChart(),
          const SizedBox(height: 8),
          _ChartLegend(
            items: const [
              _LegendItem(color: AppTheme.amber, label: 'Systolic'),
              _LegendItem(color: Color(0xFFBF8C40), label: 'Diastolic'),
              _LegendItem(
                color: Color(0x4CE8A84C),
                label: 'Normal range',
                dashed: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const BloodPressureEntryForm(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BpHeroDisplay extends StatelessWidget {
  const _BpHeroDisplay({this.latest});

  final BloodPressureLog? latest;

  @override
  Widget build(BuildContext context) {
    final log = latest;
    if (log == null) {
      return Text(
        '--/--',
        style: GoogleFonts.playfairDisplay(
          color: AppTheme.onBackground,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${log.systolic}',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.onBackground,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        Text(
          '/',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.onSurface.withAlpha(153),
            fontSize: 36,
            height: 1,
          ),
        ),
        Text(
          '${log.diastolic}',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.onBackground,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'mmHg',
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(153),
            fontSize: 14,
          ),
        ),
        if (log.pulse != null) ...[
          const SizedBox(width: 16),
          Text(
            '${log.pulse} bpm',
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(153),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart legend
// ---------------------------------------------------------------------------

class _LegendItem {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 2,
              color: item.dashed ? Colors.transparent : item.color,
              child: item.dashed
                  ? CustomPaint(painter: _DashPainter(color: item.color))
                  : null,
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: GoogleFonts.inter(
                color: AppTheme.onSurface.withAlpha(153),
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + 4, size.height / 2),
        paint,
      );
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
