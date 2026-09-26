/// fl_chart views for gas history. Single-series charts — the panel title
/// names the series, so no legends. Colors: flame = gas burned, blue = money
/// (validated pair, see gas_theme.dart).
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'gas_core.dart';
import 'gas_theme.dart';

const _tooltipText = TextStyle(
  color: Colors.white,
  fontSize: 11.5,
  fontWeight: FontWeight.w600,
  height: 1.35,
);

String _compact(double v) => v.toStringAsFixed(v < 10 && v % 1 != 0 ? 1 : 0);

double _niceInterval(double maxY) {
  if (maxY <= 0) return 1;
  final raw = maxY / 4;
  final pow10 = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  for (final m in const [1, 2, 2.5, 5, 10]) {
    if (raw <= m * pow10) return m * pow10;
  }
  return 10 * pow10;
}

/// Bars of gas burned — daily for ranges up to 45 days, weekly above that.
/// Thin rods, 4 px rounded data-ends, recessive horizontal grid.
class GasBurnBarChart extends StatelessWidget {
  const GasBurnBarChart({super.key, required this.points, this.rodWidth = 9});

  final List<DayPoint> points;
  final double rodWidth;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
            child:
                Text('No usage data for this range', style: gasSmall(context))),
      );
    }
    final maxY = points.map((p) => p.kg).reduce(math.max);
    final interval = _niceInterval(maxY);
    final labelEvery = (points.length / 6).ceil().clamp(1, 1000);

    return SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY <= 0 ? 1 : maxY * 1.18,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (v) =>
                const FlLine(color: GasPalette.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(_compact(v),
                      style: gasSmall(context).copyWith(fontSize: 10)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 ||
                      i >= points.length ||
                      ((i % labelEvery != 0) && i != points.length - 1)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('d MMM').format(points[i].day),
                        style: gasSmall(context).copyWith(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => GasPalette.ink,
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final p = points[groupIndex];
                return BarTooltipItem(
                  '${p.kg.toStringAsFixed(1)} kg\n${money(p.cost)}',
                  _tooltipText,
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].kg,
                    color: GasPalette.flame,
                    width: rodWidth,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Cost over time — 2 px line, soft fill below, ink tooltip.
class GasCostLineChart extends StatelessWidget {
  const GasCostLineChart({super.key, required this.points});

  final List<DayPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
            child: Text('Not enough data for a trend yet',
                style: gasSmall(context))),
      );
    }
    final maxY = points.map((p) => p.cost).reduce(math.max);
    final labelEvery = (points.length / 6).ceil().clamp(1, 1000).toDouble();

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _niceInterval(maxY),
            getDrawingHorizontalLine: (v) =>
                const FlLine(color: GasPalette.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: _niceInterval(maxY),
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text('$kCurrency${_compact(v)}',
                      style: gasSmall(context).copyWith(fontSize: 10)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: labelEvery,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('d MMM').format(points[i].day),
                        style: gasSmall(context).copyWith(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => GasPalette.ink,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${money(s.y)}\n'
                    '${DateFormat('d MMM').format(points[s.x.toInt().clamp(0, points.length - 1)].day)}',
                    _tooltipText,
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].cost),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              barWidth: 2,
              color: GasPalette.series,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: GasPalette.series.withValues(alpha: 0.08)),
            ),
          ],
        ),
      ),
    );
  }
}
