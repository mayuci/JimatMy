import 'package:flutter/material.dart';

import '../models/price_trend.dart';

class TrendSummaryWidget extends StatelessWidget {
  const TrendSummaryWidget({required this.trend, super.key});
  final PriceTrend trend;

  String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (trend.points.length < 2) return const SizedBox.shrink();
    final change = trend.absoluteChange;
    final percentage = trend.percentageChange;
    final lowest = trend.lowestDailyPrice;
    final highest = trend.highestDailyPrice;
    final average =
        trend.points
            .map((point) => point.averagePrice)
            .reduce((first, second) => first + second) /
        trend.points.length;
    if (change == null ||
        percentage == null ||
        lowest == null ||
        highest == null) {
      return const SizedBox.shrink();
    }

    final direction = change.abs() < .005
        ? 'remained stable'
        : change > 0
        ? 'increased'
        : 'decreased';
    final movement = change.abs() < .005
        ? 'Average price remained stable over this period.'
        : 'Average price $direction by RM ${change.abs().toStringAsFixed(2)} '
              '(${percentage.abs().toStringAsFixed(1)}%) over this period.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price summary',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Metric(label: 'Highest', value: _rm(highest)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(label: 'Average', value: _rm(average)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(label: 'Lowest', value: _rm(lowest)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F5EA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                change > 0
                    ? Icons.trending_up_rounded
                    : change < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
                color: const Color(0xFF167D55),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price insight',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(movement),
                    const SizedBox(height: 7),
                    Text(
                      '${_date(trend.points.first.recordDate)} - '
                      '${_date(trend.points.last.recordDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 72,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF167D55),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

String _rm(double value) => 'RM ${value.toStringAsFixed(2)}';
