import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/blood_pressure_log.dart';
import '../providers/health_providers.dart';

/// 30-day blood pressure line chart with normal range overlay.
///
/// Two lines: systolic (amber) and diastolic (amber 60% opacity).
/// Dashed reference lines at systolic=120 and diastolic=80 (normal upper bound).
class BloodPressureChart extends ConsumerWidget {
  const BloodPressureChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(bloodPressureLogs30DayProvider);

    if (logs.isEmpty) {
      return _EmptyChart();
    }

    return _Chart(logs: logs);
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.logs});

  final List<BloodPressureLog> logs;

  // Normal upper bounds for reference lines.
  static const double _normalSystolic = 120;
  static const double _normalDiastolic = 80;

  @override
  Widget build(BuildContext context) {
    final systolicSpots = List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), logs[i].systolic.toDouble()),
    );
    final diastolicSpots = List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), logs[i].diastolic.toDouble()),
    );

    final allValues = [
      ...logs.map((l) => l.systolic.toDouble()),
      ...logs.map((l) => l.diastolic.toDouble()),
      _normalSystolic,
      _normalDiastolic,
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).clamp(20.0, double.infinity);
    final padding = range * 0.12;

    final xMax = (logs.length - 1).toDouble();

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
            horizontalInterval: 20,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 20,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
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
                  final d = logs[idx].measuredAt;
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
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((s) {
                  final label = s.barIndex == 0 ? 'SYS' : 'DIA';
                  return LineTooltipItem(
                    '$label ${s.y.toStringAsFixed(0)}',
                    GoogleFonts.inter(color: AppTheme.amber, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Systolic line (solid amber)
            LineChartBarData(
              spots: systolicSpots,
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
              belowBarData: BarAreaData(show: false),
            ),
            // Diastolic line (muted amber)
            LineChartBarData(
              spots: diastolicSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.amber.withAlpha(153),
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, b, i) => FlDotCirclePainter(
                  radius: 2.5,
                  color: AppTheme.amber.withAlpha(153),
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
            // Normal systolic reference (dashed)
            LineChartBarData(
              spots: [
                FlSpot(0, _normalSystolic),
                FlSpot(xMax, _normalSystolic),
              ],
              isCurved: false,
              color: AppTheme.amber.withAlpha(76),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            // Normal diastolic reference (dashed)
            LineChartBarData(
              spots: [
                FlSpot(0, _normalDiastolic),
                FlSpot(xMax, _normalDiastolic),
              ],
              isCurved: false,
              color: AppTheme.amber.withAlpha(76),
              barWidth: 1,
              dashArray: [5, 5],
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

  double _xInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 15) return 3;
    return 7;
  }
}

class _EmptyChart extends StatelessWidget {
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
          'Log your first reading to see the chart',
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(128),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
