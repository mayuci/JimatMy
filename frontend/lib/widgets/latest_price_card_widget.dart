import 'package:flutter/material.dart';

import '../models/latest_price.dart';
import 'price_freshness_widget.dart';

class LatestPriceCardWidget extends StatelessWidget {
  const LatestPriceCardWidget({
    required this.price,
    this.onViewStore,
    super.key,
  });
  final LatestPrice price;
  final VoidCallback? onViewStore;

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
                  Expanded(
                    child: Text(
                      price.premiseName,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'RM ${price.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (onViewStore != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              PriceFreshnessWidget(
                reliability: price.reliability,
                compact: true,
              ),
              const SizedBox(height: 8),
              Text(
                price.address,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(child: Text('${price.district}, ${price.state}')),
                  Text(
                    _formatDate(price.recordDate),
                    style: Theme.of(context).textTheme.bodySmall,
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
