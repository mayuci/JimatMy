import 'package:flutter/material.dart';

import '../models/price_comparison.dart';

class BestPriceSummaryWidget extends StatelessWidget {
  const BestPriceSummaryWidget({
    required this.comparison,
    this.onViewStore,
    super.key,
  });

  final PriceComparison comparison;
  final VoidCallback? onViewStore;

  @override
  Widget build(BuildContext context) {
    final best = comparison.cheapestOption;
    if (best == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final saving = comparison.savingDifference;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F5EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Best price',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'RM ${best.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          if (onViewStore == null)
            Text(
              best.premiseName,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            )
          else
            Tooltip(
              message: 'View ${best.premiseName} store details',
              child: Semantics(
                button: true,
                label: 'View ${best.premiseName} store details',
                child: TextButton.icon(
                  onPressed: onViewStore,
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(
                    best.premiseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          if (saving != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Potential saving RM ${saving.toStringAsFixed(2)} against the highest shown price',
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
