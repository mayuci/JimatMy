import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/price_trend.dart';

class PriceTrendChartWidget extends StatelessWidget {
  const PriceTrendChartWidget({required this.points, super.key});

  final List<PriceTrendPoint> points;

  String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _fullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final averages = points.map((point) => point.averagePrice).toList();
    final minimum = averages.reduce((a, b) => a < b ? a : b);
    final maximum = averages.reduce((a, b) => a > b ? a : b);
    final padding = (maximum - minimum).abs() < 0.01
        ? 0.5
        : (maximum - minimum) * 0.15;
    final labelIndexes = <int>{
      0,
      (points.length - 1) ~/ 3,
      ((points.length - 1) * 2) ~/ 3,
      points.length - 1,
    };

    return Card(
      color: const Color(0xFFF1FAF4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 22, 16, 12),
        child: AspectRatio(
          aspectRatio: 1.55,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: minimum - padding,
              maxY: maximum + padding,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: ((maximum - minimum) + padding * 2) / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: colors.outlineVariant.withValues(alpha: 0.55),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        'RM${value.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 ||
                          index >= points.length ||
                          !labelIndexes.contains(index)) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          _shortDate(points[index].recordDate),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colors.inverseSurface,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final point = points[spot.x.round()];
                    return LineTooltipItem(
                      '${_fullDate(point.recordDate)}\nRM ${point.averagePrice.toStringAsFixed(2)}',
                      TextStyle(
                        color: colors.onInverseSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var index = 0; index < points.length; index++)
                      FlSpot(index.toDouble(), points[index].averagePrice),
                  ],
                  isCurved: false,
                  color: colors.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, _) =>
                        spot.x.round() == points.length - 1,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 5,
                      color: colors.primary,
                      strokeWidth: 3,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
