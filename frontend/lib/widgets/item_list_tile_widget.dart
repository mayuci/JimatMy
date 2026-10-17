import 'package:flutter/material.dart';

import '../models/item.dart';
import 'item_image_widget.dart';

class ItemListTileWidget extends StatelessWidget {
  const ItemListTileWidget({
    required this.item,
    required this.onTap,
    super.key,
  });
  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lowestPrice = item.lowestPrice;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('search-item-action-${item.itemCode}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ItemImage(
                itemCode: item.itemCode,
                itemName: item.itemName,
                category: item.itemCategory,
                group: item.itemGroup,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lowestPrice == null
                          ? 'Price unavailable'
                          : 'From RM ${lowestPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: lowestPrice == null
                            ? colors.onSurfaceVariant
                            : const Color(0xFF167D55),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.premiseCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${item.premiseCount} ${item.premiseCount == 1 ? 'premise' : 'premises'}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
