import 'package:flutter/material.dart';

import '../models/latest_price.dart';
import 'price_freshness_widget.dart';

class ComparisonPriceCardWidget extends StatelessWidget {
  const ComparisonPriceCardWidget({
    required this.price,
    required this.rank,
    this.onViewStore,
    this.onSave,
    super.key,
  });

  final LatestPrice price;
  final int rank;
  final VoidCallback? onViewStore;
  final VoidCallback? onSave;

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isBest = rank == 1;
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewStore,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isBest
                          ? colors.primary
                          : colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBest ? 'Best Price' : '#$rank',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isBest
                            ? colors.onPrimary
                            : colors.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'RM ${price.price.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (onSave != null)
                    IconButton(
                      tooltip: 'Save this price comparison',
                      onPressed: onSave,
                      icon: const Icon(Icons.bookmark_add_outlined),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              PriceFreshnessWidget(
                reliability: price.reliability,
                compact: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      price.premiseName,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (onViewStore != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              Text(
                price.address,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${price.district}, ${price.state}')),
                  if (onViewStore != null)
                    TextButton.icon(
                      onPressed: onViewStore,
                      icon: const Icon(Icons.storefront_outlined, size: 17),
                      label: const Text('View store'),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colors.outline,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Recorded ${_formatDate(price.recordDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (onViewStore == null) return card;
    final label = 'View ${price.premiseName} store details';
    return Tooltip(
      message: label,
      child: Semantics(button: true, label: label, child: card),
    );
  }
}
