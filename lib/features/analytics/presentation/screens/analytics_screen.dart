import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: const [
          _StreakSection(),
          SizedBox(height: 16),
          _AdherenceSection(),
          SizedBox(height: 16),
          _CorrelationSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppTheme.onSurface.withAlpha(128),
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card shell
// ---------------------------------------------------------------------------

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Streak section
// ---------------------------------------------------------------------------

class _StreakSection extends ConsumerWidget {
  const _StreakSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Injection Streaks'),
        _AnalyticsCard(
          child: Row(
            children: [
              _StatTile(
                label: 'Current Streak',
                value: '${streak.currentStreak}',
                unit: streak.currentStreak == 1 ? 'day' : 'days',
                highlight: streak.currentStreak > 0,
              ),
              const _Divider(),
              _StatTile(
                label: 'Longest Streak',
                value: '${streak.longestStreak}',
                unit: streak.longestStreak == 1 ? 'day' : 'days',
              ),
              const _Divider(),
              _StatTile(
                label: 'Total Days',
                value: '${streak.totalDaysLogged}',
                unit: 'logged',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: AppTheme.divider,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              color: highlight ? AppTheme.amber : AppTheme.onBackground,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              color: highlight
                  ? AppTheme.amber.withAlpha(204)
                  : AppTheme.onSurface.withAlpha(153),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.onSurface.withAlpha(128),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Adherence section
// ---------------------------------------------------------------------------

class _AdherenceSection extends ConsumerWidget {
  const _AdherenceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adherenceProvider);
    final pct = (data.rate * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Adherence Rate — Last 30 Days'),
        _AnalyticsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Big percentage
                  Text(
                    '$pct%',
                    style: GoogleFonts.playfairDisplay(
                      color: _adherenceColor(data.rate),
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.actualDays} of ${data.expectedDays} scheduled days',
                        style: GoogleFonts.inter(
                          color: AppTheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'injections logged',
                        style: GoogleFonts.inter(
                          color: AppTheme.onSurface.withAlpha(153),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.rate,
                  minHeight: 8,
                  backgroundColor: AppTheme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _adherenceColor(data.rate),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.expectedDays == 0
                    ? 'Set up reminders to track adherence'
                    : _adherenceLabel(data.rate),
                style: GoogleFonts.inter(
                  color: AppTheme.onSurface.withAlpha(128),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _adherenceColor(double rate) {
    if (rate >= 0.8) return const Color(0xFF7EC699);
    if (rate >= 0.5) return AppTheme.amber;
    return AppTheme.error;
  }

  String _adherenceLabel(double rate) {
    if (rate >= 0.9) return 'Excellent — keep it up!';
    if (rate >= 0.7) return 'Good consistency';
    if (rate >= 0.5) return 'Room to improve';
    return 'Try to stick to your schedule';
  }
}

// ---------------------------------------------------------------------------
// Correlation chart: weight (line) + injection frequency (bars)
// ---------------------------------------------------------------------------

class _CorrelationSection extends ConsumerWidget {
  const _CorrelationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(correlationProvider);
    final hasWeight = points.any((p) => p.weightKg != null);
    final hasInjections = points.any((p) => p.injectionCount > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Weight vs Injection Frequency — Last 30 Days'),
        _AnalyticsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend
              Row(
                children: [
                  _LegendDot(color: AppTheme.amber, label: 'Weight (kg)'),
                  const SizedBox(width: 16),
                  _LegendDot(
                    color: AppTheme.amber.withAlpha(76),
                    label: 'Injections',
                    isBar: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasWeight && !hasInjections)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'Log weight and injections to see correlation',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppTheme.onSurface.withAlpha(128),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(height: 220, child: _CorrelationChart(points: points)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.isBar = false,
  });

  final Color color;
  final String label;
  final bool isBar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBar)
          Container(width: 12, height: 8, color: color)
        else
          Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(179),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CorrelationChart extends StatelessWidget {
  const _CorrelationChart({required this.points});

  final List<DayCorrelationPoint> points;

  @override
  Widget build(BuildContext context) {
    // Compute weight spots (skip null days).
    final weightSpots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      if (points[i].weightKg != null) {
        weightSpots.add(FlSpot(i.toDouble(), points[i].weightKg!));
      }
    }

    // Max injection count for bar scale.
    final maxInjections = points
        .map((p) => p.injectionCount)
        .fold(0, math.max)
        .toDouble();

    // Weight Y range.
    double? minWeight, maxWeight;
    if (weightSpots.isNotEmpty) {
      minWeight = weightSpots.map((s) => s.y).reduce(math.min);
      maxWeight = weightSpots.map((s) => s.y).reduce(math.max);
      final padding = math.max((maxWeight - minWeight) * 0.2, 1.0);
      minWeight -= padding;
      maxWeight += padding;
    }

    final DateFormat fmt = DateFormat('M/d');

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxInjections == 0 ? 3 : maxInjections + 1,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.background,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final p = points[group.x.toInt()];
              final date = fmt.format(p.date);
              final wt = p.weightKg != null
                  ? ' · ${p.weightKg!.toStringAsFixed(1)} kg'
                  : '';
              return BarTooltipItem(
                '$date\n${p.injectionCount} inj$wt',
                GoogleFonts.inter(color: AppTheme.amber, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  fmt.format(points[idx].date),
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurface.withAlpha(128),
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(points.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: points[i].injectionCount.toDouble(),
                color: AppTheme.amber.withAlpha(
                  points[i].injectionCount > 0 ? 102 : 26,
                ),
                width: 6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ],
          );
        }),
        // Weight overlay drawn as extra lines data via LineChart inside a Stack.
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }
}
