import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/weight_log.dart';
import '../providers/weight_providers.dart';

/// 30-day weight line chart using fl_chart.
/// Shows amber accent line for weight, dashed amber line for goal weight.
class WeightChart extends ConsumerWidget {
  const WeightChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(weightLogs30DayProvider);
    final goalKg = ref.watch(goalWeightProvider);

    if (logs.isEmpty) {
      return _EmptyChart(goalKg: goalKg);
    }

    return _Chart(logs: logs, goalKg: goalKg);
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.logs, this.goalKg});

  final List<WeightLog> logs;
  final double? goalKg;

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots(logs);
    final minY = _computeMinY(logs, goalKg);
    final maxY = _computeMaxY(logs, goalKg);
    final yRange = maxY - minY;
    final padding = yRange * 0.15;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _gridInterval(yRange),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: _gridInterval(yRange),
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(0)} kg',
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurface.withAlpha(153),
                    fontSize: 9,
                  ),
                ),
              ),
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
                interval: _xInterval(logs.length),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= logs.length) {
                    return const SizedBox.shrink();
                  }
                  final d = logs[idx].date;
                  return Text(
                    '${d.month}/${d.day}',
                    style: GoogleFonts.inter(
                      color: AppTheme.onSurface.withAlpha(128),
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.background,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} kg',
                      GoogleFonts.inter(color: AppTheme.amber, fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            // Weight line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.amber,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, b, i) => FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.amber,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.amber.withAlpha(51),
                    AppTheme.amber.withAlpha(0),
                  ],
                ),
              ),
            ),
            // Goal line (dashed)
            if (goalKg != null)
              LineChartBarData(
                spots: [
                  FlSpot(0, goalKg!),
                  FlSpot((logs.length - 1).toDouble(), goalKg!),
                ],
                isCurved: false,
                color: AppTheme.amber.withAlpha(153),
                barWidth: 1.5,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  List<FlSpot> _buildSpots(List<WeightLog> logs) {
    return List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), logs[i].weightKg),
    );
  }

  double _computeMinY(List<WeightLog> logs, double? goal) {
    var min = logs.map((l) => l.weightKg).reduce((a, b) => a < b ? a : b);
    if (goal != null && goal < min) min = goal;
    return min;
  }

  double _computeMaxY(List<WeightLog> logs, double? goal) {
    var max = logs.map((l) => l.weightKg).reduce((a, b) => a > b ? a : b);
    if (goal != null && goal > max) max = goal;
    return max;
  }

  double _gridInterval(double range) {
    if (range <= 0) return 1;
    if (range < 5) return 1;
    if (range < 20) return 2;
    return 5;
  }

  double _xInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 15) return 3;
    return 7;
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({this.goalKg});

  final double? goalKg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Log your first weight to see the chart',
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(128),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
