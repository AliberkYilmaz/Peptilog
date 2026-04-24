import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/health_providers.dart';
import '../widgets/blood_pressure_chart.dart';
import '../widgets/blood_pressure_entry_form.dart';
import '../widgets/sleep_chart.dart';
import '../widgets/sleep_entry_form.dart';

/// Health tab — tab index 3 in the main bottom nav.
///
/// Layout (top → bottom):
///   • Sleep section: hero hours display, 30-day chart, entry form
///   • Blood pressure section: hero SYS/DIA display, 30-day chart, entry form
class HealthBody extends ConsumerWidget {
  const HealthBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sleep ──────────────────────────────────────────────────────────
          _SectionHeader(label: 'Sleep', icon: Icons.bedtime_outlined),
          const SizedBox(height: 12),
          const _SleepHeroDisplay(),
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
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 24),

          // ── Blood Pressure ─────────────────────────────────────────────────
          _SectionHeader(label: 'Blood Pressure', icon: Icons.favorite_outline),
          const SizedBox(height: 12),
          const _BpHeroDisplay(),
          const SizedBox(height: 16),
          const BloodPressureChart(),
          const SizedBox(height: 8),
          _ChartLegend(
            items: const [
              _LegendItem(color: AppTheme.amber, label: 'Systolic'),
              _LegendItem(
                color: Color(0xFFBF8C40), // amber ~60%
                label: 'Diastolic',
              ),
              _LegendItem(
                color: Color(0x4CE8A84C), // amber ~30%
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

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.amber),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep hero
// ---------------------------------------------------------------------------

class _SleepHeroDisplay extends ConsumerWidget {
  const _SleepHeroDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestSleepProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          latest != null ? latest.hours.toStringAsFixed(1) : '--',
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
// Blood pressure hero
// ---------------------------------------------------------------------------

class _BpHeroDisplay extends ConsumerWidget {
  const _BpHeroDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestBloodPressureProvider);

    if (latest == null) {
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
          '${latest.systolic}',
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
          '${latest.diastolic}',
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
        if (latest.pulse != null) ...[
          const SizedBox(width: 16),
          Text(
            '${latest.pulse} bpm',
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
