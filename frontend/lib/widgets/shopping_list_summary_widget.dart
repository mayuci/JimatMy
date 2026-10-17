import 'package:flutter/material.dart';

import '../models/planner_models.dart';

class ShoppingListSummaryWidget extends StatelessWidget {
  const ShoppingListSummaryWidget({
    required this.list,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    super.key,
  });
  final ShoppingListSummary list;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  String _updatedLabel() {
    final value = list.updatedAt?.toLocal();
    if (value == null) return 'Updated recently';
    return 'Updated ${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = list.itemCount == 0
        ? 0.0
        : list.completedItemCount / list.itemCount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F5EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_basket_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'List actions',
                    onSelected: (value) =>
                        value == 'rename' ? onRename() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(child: Text('${list.itemCount} items')),
                  Text(
                    'RM ${list.estimatedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 7),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${list.completedItemCount} of ${list.itemCount} completed',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(_updatedLabel(), style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
