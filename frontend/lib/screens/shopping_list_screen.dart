import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/planner_models.dart';
import '../l10n/l10n.dart';
import '../providers/planner_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/api_service.dart';
import '../widgets/add_item_sheet_widget.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/mobile_content.dart';
import '../widgets/shopping_list_item_widget.dart';
import 'best_places_screen.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({required this.listId, super.key});
  final String listId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        ShoppingListProvider(context.read<ApiService>(), listId)..load(),
    child: const _ShoppingListView(),
  );
}

class _ShoppingListView extends StatefulWidget {
  const _ShoppingListView();

  @override
  State<_ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<_ShoppingListView> {
  int _segment = 0;

  void _error(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _addItem(BuildContext context) async {
    final provider = context.read<ShoppingListProvider>();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddItemSheetWidget(
        apiService: context.read<ApiService>(),
        onAdd: (item, quantity) => provider.addItem(item.itemCode, quantity),
      ),
    );
  }

  Future<void> _rename(BuildContext context, ShoppingListDetail list) async {
    final controller = TextEditingController(text: list.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.renameListDialog),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(labelText: context.l10n.listName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.l10n.rename),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final error = await context.read<PlannerProvider>().renameList(
      list.shoppingListId,
      name,
    );
    if (!context.mounted) return;
    if (error != null) {
      _error(context, error);
    } else {
      await context.read<ShoppingListProvider>().load();
    }
  }

  Future<void> _deleteList(
    BuildContext context,
    ShoppingListDetail list,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteShoppingListQuestion),
        content: Text(context.l10n.deleteListConfirm(list.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<PlannerProvider>().deleteList(
      list.shoppingListId,
    );
    if (!context.mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      _error(context, error);
    }
  }

  Future<void> _removeItem(BuildContext context, ShoppingListItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removeItemQuestion),
        content: Text(context.l10n.removeItemConfirm(item.itemName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<ShoppingListProvider>().removeItem(item);
    if (error != null && context.mounted) _error(context, error);
  }

  @override
  Widget build(BuildContext context) => Consumer<ShoppingListProvider>(
    builder: (context, provider, _) {
      final list = provider.list;
      final budgetAmount = context
          .watch<PlannerProvider>()
          .overview
          ?.budget
          ?.amount;
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(context.l10n.shoppingListTitle),
          actions: [
            if (list != null)
              PopupMenuButton<String>(
                onSelected: (value) => value == 'rename'
                    ? _rename(context, list)
                    : _deleteList(context, list),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(context.l10n.rename),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(context.l10n.delete),
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: _content(context, provider),
        bottomNavigationBar: list == null
            ? null
            : _ListTotalBar(
                list: list,
                budgetAmount: budgetAmount,
                onCompare: list.items.any((item) => !item.isChecked)
                    ? () => _openCompare(context, list)
                    : null,
              ),
      );
    },
  );

  void _openCompare(BuildContext context, ShoppingListDetail list) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BestPlacesScreen(listId: list.shoppingListId),
      ),
    );
  }

  Widget _content(BuildContext context, ShoppingListProvider provider) {
    if (provider.isLoading && provider.list == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.list == null) {
      if (provider.errorCode == 'SHOPPING_LIST_NOT_FOUND') {
        return AppStateWidget(
          icon: Icons.list_alt_outlined,
          title: context.l10n.shoppingListNotFound,
          message: context.l10n.listDeletedMessage,
          actionLabel: context.l10n.backToPlanner,
          onAction: () => Navigator.pop(context),
        );
      }
      return AppStateWidget(
        icon: Icons.wifi_off_outlined,
        title: context.l10n.couldntLoadList,
        message: provider.errorMessage!,
        actionLabel: context.l10n.tryAgain,
        onAction: provider.load,
      );
    }
    final list = provider.list;
    if (list == null) return const SizedBox.shrink();
    final visibleItems = list.items
        .where((item) => _segment == 0 ? !item.isChecked : item.isChecked)
        .toList(growable: false);

    return MobileContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 0, label: Text(context.l10n.myList)),
                  ButtonSegment(value: 1, label: Text(context.l10n.completed)),
                ],
                selected: {_segment},
                onSelectionChanged: (values) =>
                    setState(() => _segment = values.first),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.itemCount(list.itemCount),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        context.l10n.completedItemsCount(list.completedItemCount),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.renameListDialog,
                  onPressed: () => _rename(context, list),
                  icon: const Icon(Icons.edit_outlined),
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: () => _addItem(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(context.l10n.addItem),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (list.items.isEmpty)
                    AppStateWidget(
                      icon: Icons.add_shopping_cart_outlined,
                      title: context.l10n.yourListIsEmpty,
                      message: context.l10n.emptyListMessage,
                      actionLabel: context.l10n.addItem,
                      onAction: () => _addItem(context),
                    )
                  else if (visibleItems.isEmpty)
                    AppStateWidget(
                      icon: _segment == 0
                          ? Icons.task_alt_outlined
                          : Icons.hourglass_empty_rounded,
                      title: _segment == 0
                          ? context.l10n.everythingCompleted
                          : context.l10n.noCompletedYet,
                      message: _segment == 0
                          ? context.l10n.completedHint
                          : context.l10n.completedEmptyHint,
                      actionLabel: _segment == 0 ? context.l10n.addItem : null,
                      onAction: _segment == 0 ? () => _addItem(context) : null,
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < visibleItems.length;
                              index++
                            ) ...[
                              ShoppingListItemWidget(
                                item: visibleItems[index],
                                busy: provider.isSaving,
                                onCompleted: (value) async {
                                  final error = await provider.setCompleted(
                                    visibleItems[index],
                                    value,
                                  );
                                  if (error != null && context.mounted) {
                                    _error(context, error);
                                  }
                                },
                                onQuantityChanged: (value) async {
                                  final error = await provider.updateQuantity(
                                    visibleItems[index],
                                    value,
                                  );
                                  if (error != null && context.mounted) {
                                    _error(context, error);
                                  }
                                },
                                onRemove: () =>
                                    _removeItem(context, visibleItems[index]),
                              ),
                              if (index != visibleItems.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 92,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTotalBar extends StatelessWidget {
  const _ListTotalBar({
    required this.list,
    required this.budgetAmount,
    required this.onCompare,
  });

  final ShoppingListDetail list;
  final double? budgetAmount;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final difference = budgetAmount == null
        ? null
        : budgetAmount! - list.estimatedTotal;
    final over = difference != null && difference < 0;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 10,
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.estimatedTotal,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    'RM ${list.estimatedTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Text(
                difference == null
                    ? context.l10n.noBudgetSet
                    : over
                    ? context.l10n.overBudget(
                        difference.abs().toStringAsFixed(2),
                      )
                    : context.l10n.withinBudget(
                        difference.toStringAsFixed(2),
                      ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: over ? colors.error : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onCompare,
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(context.l10n.findBestPlaces),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
