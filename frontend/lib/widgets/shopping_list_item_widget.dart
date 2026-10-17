import 'package:flutter/material.dart';

import '../models/planner_models.dart';
import 'item_image_widget.dart';
import 'price_freshness_widget.dart';

class ShoppingListItemWidget extends StatelessWidget {
  const ShoppingListItemWidget({
    required this.item,
    required this.busy,
    required this.onCompleted,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  final ShoppingListItem item;
  final bool busy;
  final ValueChanged<bool> onCompleted;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: item.isChecked ? 0.62 : 1,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: item.isChecked ? colors.surfaceContainerHighest : Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 13, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemImage(
                itemCode: item.itemCode,
                itemName: item.itemName,
                category: '',
                width: 68,
                height: 68,
                borderRadius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 5),
                    if (item.isPriceAvailable) ...[
                      Text(
                        'Best price RM ${item.bestPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.cheapestPremise?.premiseName.trim().isNotEmpty ==
                          true)
                        Text(
                          item.cheapestPremise!.premiseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      if (item.reliability.freshnessStatus !=
                          'unavailable') ...[
                        const SizedBox(height: 5),
                        PriceFreshnessWidget(
                          reliability: item.reliability,
                          compact: true,
                        ),
                      ],
                    ] else
                      Text(
                        'Price unavailable',
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _QuantityButton(
                          tooltip: 'Decrease quantity',
                          icon: Icons.remove,
                          onPressed: busy || item.quantity <= 1
                              ? null
                              : () => onQuantityChanged(item.quantity - 1),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            _quantityLabel(item.quantity),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _QuantityButton(
                          tooltip: 'Increase quantity',
                          icon: Icons.add,
                          onPressed: busy
                              ? null
                              : () => onQuantityChanged(item.quantity + 1),
                        ),
                        const SizedBox(width: 8),
                        if (item.estimatedLineTotal != null)
                          Expanded(
                            child: Text(
                              'Line total RM ${item.estimatedLineTotal!.toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: item.isChecked
                        ? 'Move back to my list'
                        : 'Mark item completed',
                    child: Checkbox(
                      value: item.isChecked,
                      visualDensity: VisualDensity.compact,
                      onChanged: busy
                          ? null
                          : (value) => onCompleted(value ?? false),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove item',
                    visualDensity: VisualDensity.compact,
                    onPressed: busy ? null : onRemove,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 30,
    child: IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      iconSize: 17,
      icon: Icon(icon),
    ),
  );
}

String _quantityLabel(double quantity) =>
    quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2);
