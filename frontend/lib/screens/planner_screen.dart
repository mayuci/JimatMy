import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/planner_models.dart';
import '../l10n/l10n.dart';
import '../providers/planner_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/budget_summary_widget.dart';
import '../widgets/shopping_list_summary_widget.dart';
import '../widgets/mobile_content.dart';
import 'shopping_list_screen.dart';
import 'login_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _basketPageController = PageController(viewportFraction: 0.86);
  int _basketPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _basketPageController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    final name = await _textDialog(
      title: context.l10n.createShoppingList,
      label: context.l10n.listName,
    );
    if (name == null || !mounted) return;
    final error = await context.read<PlannerProvider>().createList(name);
    if (error != null && mounted) _showError(error);
  }

  Future<void> _previewTemplate(BasketTemplate template) async {
    final create = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .9,
        builder: (context, controller) => Column(
          children: [
            ListTile(
              title: Text(
                template.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                context.l10n.weeklyBasketSubtitle(template.household),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: template.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = template.items[index];
                  return ListTile(
                    dense: true,
                    title: Text(item.itemName),
                    subtitle: Text(
                      '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} × ${item.unit}',
                    ),
                    trailing: Text(
                      item.estimatedLineTotal == null
                          ? context.l10n.unavailable
                          : 'RM ${item.estimatedLineTotal!.toStringAsFixed(2)}',
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: Text(
                      context.l10n.createListWithTotal(
                        'RM ${template.estimatedTotal.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (create != true || !mounted) return;
    final provider = context.read<PlannerProvider>();
    final list = await provider.createFromTemplate(template.templateKey);
    if (!mounted) return;
    if (list == null) {
      _showError(provider.errorMessage ?? context.l10n.basketCreateFailed);
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListScreen(listId: list.shoppingListId),
      ),
    );
    if (mounted) provider.load();
  }

  Future<void> _setBudget() async {
    final current = context.read<PlannerProvider>().overview?.budget?.amount;
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _BudgetDialog(currentAmount: current),
    );
    if (amount == null || !mounted) return;
    final error = await context.read<PlannerProvider>().setBudget(amount);
    if (!mounted) return;
    if (error != null) _showError(error);
  }

  Future<String?> _textDialog({
    required String title,
    required String label,
    String initialValue = '',
    String confirmLabel = 'Create',
  }) {
    final controller = TextEditingController(text: initialValue);
    String? validation;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: label,
              errorText: validation,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  setDialogState(() => validation = context.l10n.enterListName);
                } else {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameList(ShoppingListSummary list) async {
    final name = await _textDialog(
      title: context.l10n.renameShoppingList,
      label: context.l10n.listName,
      initialValue: list.name,
      confirmLabel: context.l10n.rename,
    );
    if (name == null || !mounted) return;
    final error = await context.read<PlannerProvider>().renameList(
      list.shoppingListId,
      name,
    );
    if (error != null && mounted) _showError(error);
  }

  Future<void> _deleteList(ShoppingListSummary list) async {
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
    if (confirmed != true || !mounted) return;
    final error = await context.read<PlannerProvider>().deleteList(
      list.shoppingListId,
    );
    if (error != null && mounted) _showError(error);
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final planner = context.watch<PlannerProvider>();
    if (auth.isAuthenticated &&
        planner.overview == null &&
        !planner.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<AuthProvider>().isAuthenticated) {
          context.read<PlannerProvider>().load();
        }
      });
    }
    if (auth.isAuthenticated &&
        !planner.hasLoadedTemplates &&
        !planner.isLoadingTemplates) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<PlannerProvider>().loadTemplates();
      });
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.plannerTitle)),
      body: MobileContent(
        child: Consumer<PlannerProvider>(
          builder: (context, provider, _) {
            if (auth.isRestoring) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!auth.isAuthenticated) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppStateWidget(
                    icon: Icons.lock_outline,
                    title: context.l10n.signInToPlan,
                    message: context.l10n.plannerSignInMessage,
                    actionLabel: context.l10n.login,
                    onAction: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                ),
              );
            }
            if (provider.isLoading && provider.overview == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null && provider.overview == null) {
              return AppStateWidget(
                icon: Icons.wifi_off_outlined,
                title: context.l10n.plannerUnavailable,
                message: provider.errorMessage!,
                actionLabel: context.l10n.retry,
                onAction: provider.load,
              );
            }
            final overview = provider.overview;
            if (overview == null) return const SizedBox.shrink();
            return RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: BudgetSummaryWidget(
                        overview: overview,
                        onEdit: _setBudget,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: provider.isSaving ? null : _createList,
                            icon: const Icon(Icons.add),
                            label: Text(context.l10n.createListShort),
                          ),
                          if (provider.templates.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            Text(
                              context.l10n.startWithBasket,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.reviewedWeeklyEssentials,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 152,
                              child: PageView.builder(
                                controller: _basketPageController,
                                onPageChanged: (page) =>
                                    setState(() => _basketPage = page),
                                itemCount: provider.templates.length,
                                itemBuilder: (context, index) {
                                  final template = provider.templates[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: provider.isSaving
                                            ? null
                                            : () => _previewTemplate(template),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.shopping_basket_outlined,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                template.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              Text(
                                                template.household,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              const Spacer(),
                                              Text(
                                                'RM ${template.estimatedTotal.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              Text(
                                                context.l10n.templateItemsCount(
                                                      template.itemCount,
                                                    ) +
                                                    (template.unavailableItemCount ==
                                                            0
                                                        ? ''
                                                        : context.l10n
                                                              .templateUnavailableCount(
                                                                template
                                                                    .unavailableItemCount,
                                                              )),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (
                                  var i = 0;
                                  i < provider.templates.length;
                                  i++
                                ) ...[
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: i == _basketPage ? 18 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: i == _basketPage
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.yourShoppingLists,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (overview.lists.isEmpty)
                    AppStateWidget(
                      icon: Icons.playlist_add_outlined,
                      title: context.l10n.noShoppingListsYet,
                      message: context.l10n.startPlanningMessage,
                      actionLabel: context.l10n.createYourFirstList,
                      onAction: _createList,
                    )
                  else
                    ...overview.lists.map(
                      (list) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: ShoppingListSummaryWidget(
                              list: list,
                              onRename: () => _renameList(list),
                              onDelete: () => _deleteList(list),
                              onTap: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShoppingListScreen(
                                      listId: list.shoppingListId,
                                    ),
                                  ),
                                );
                                if (mounted) provider.load();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Dedicated budget editor. Owning its own [TextEditingController] ties the
/// controller lifecycle to the dialog route, so it is disposed only when the
/// dialog is fully removed (after the closing animation), never while the text
/// field still references it.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.currentAmount});

  final double? currentAmount;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;
  String? _validation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentAmount?.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_saving) return;
    final parsed = double.tryParse(_controller.text);
    if (parsed == null || parsed <= 0) {
      setState(() => _validation = context.l10n.enterPositiveAmount);
      return;
    }
    // Guard the button synchronously so a double tap cannot pop twice.
    setState(() => _saving = true);
    Navigator.pop(context, parsed);
  }

  void _cancel() {
    if (_saving) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.currentAmount == null
            ? context.l10n.setMonthlyBudget
            : context.l10n.editMonthlyBudget,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,8}(\.\d{0,2})?')),
        ],
        decoration: InputDecoration(
          labelText: context.l10n.budgetAmountLabel,
          errorText: _validation,
          prefixText: 'RM ',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _cancel,
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}
