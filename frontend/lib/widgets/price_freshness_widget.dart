import 'package:flutter/material.dart';

import '../models/price_reliability.dart';

class PriceFreshnessWidget extends StatelessWidget {
  const PriceFreshnessWidget({
    required this.reliability,
    this.compact = false,
    super.key,
  });
  final PriceReliability reliability;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unavailable = reliability.freshnessStatus == 'unavailable';
    final color = switch (reliability.freshnessStatus) {
      'fresh' => colors.primary,
      'recent' => const Color(0xFF8A6500),
      'old' => colors.error,
      _ => colors.onSurfaceVariant,
    };
    final freshness = switch (reliability.freshnessStatus) {
      'fresh' => 'Fresh price',
      'recent' => 'Recent price',
      'old' => 'Older price',
      _ => 'Price unavailable',
    };
    final age = reliability.ageDays;
    final date = reliability.latestRecordDate;
    final detail = unavailable
        ? null
        : '${age == 0 ? 'Updated today' : 'Updated $age day${age == 1 ? '' : 's'} ago'}'
              '${date == null ? '' : ' • ${_date(date)}'}';
    return Wrap(
      spacing: 7,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            freshness,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        if (detail != null)
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        if (reliability.premiseCount > 0 && !compact)
          Text(
            '${_coverage(reliability.coverageStatus)} coverage • ${reliability.premiseCount} premises',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }

  static String _coverage(String value) => switch (value) {
    'wide' => 'Wide',
    'moderate' => 'Moderate',
    'limited' => 'Limited',
    _ => 'No',
  };

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
