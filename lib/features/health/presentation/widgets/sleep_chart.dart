import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/sleep_log.dart';
import '../providers/health_providers.dart';

/// 30-day sleep hours line chart using fl_chart.
class SleepChart extends ConsumerWidget {
  const SleepChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(sleepLogs30DayProvider);

    if (logs.isEmpty) {
      return _EmptyChart();
    }

    return _Chart(logs: logs);
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.logs});

  final List<SleepLog> logs;

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      logs.length,
      (i) => FlSpot(i.toDouble(), logs[i].hours),
    );

    final allHours = logs.map((l) => l.hours);
    final minH = allHours.reduce((a, b) => a < b ? a : b);
    final maxH = allHours.reduce((a, b) => a > b ? a : b);
    final range = (maxH - minH).clamp(2.0, double.infinity);
    final padding = range * 0.15;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      child: LineChart(
        LineChartData(
          minY: (minH - padding).clamp(0, double.infinity),
          maxY: maxH + padding,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _interval(maxH),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: _interval(maxH),
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(0)}h',
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
                      '${s.y.toStringAsFixed(1)}h',
                      GoogleFonts.inter(color: AppTheme.amber, fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
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
          ],
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  double _interval(double maxH) {
    if (maxH <= 4) return 1;
    if (maxH <= 10) return 2;
    return 4;
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
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Log your first sleep entry to see the chart',
          style: GoogleFonts.inter(
            color: AppTheme.onSurface.withAlpha(128),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
