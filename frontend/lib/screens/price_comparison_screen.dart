import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/price_comparison_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/best_price_summary_widget.dart';
import '../widgets/comparison_price_card_widget.dart';
import '../widgets/item_image_widget.dart';
import '../widgets/mobile_content.dart';
import 'login_screen.dart';
import 'planner_screen.dart';
import 'store_detail_screen.dart';

class PriceComparisonScreen extends StatelessWidget {
  const PriceComparisonScreen({required this.itemCode, super.key});
  final int itemCode;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        PriceComparisonProvider(context.read<ApiService>(), itemCode)..load(),
    child: const _PriceComparisonView(),
  );
}

class _PriceComparisonView extends StatelessWidget {
  const _PriceComparisonView();

  @override
  Widget build(BuildContext context) => Consumer<PriceComparisonProvider>(
    builder: (context, provider, _) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.priceComparisonTitle)),
      body: MobileContent(
        child: Column(
          children: [
            _Filters(provider: provider),
            Expanded(child: _buildResults(context, provider)),
          ],
        ),
      ),
      bottomNavigationBar: provider.comparison == null
          ? null
          : _AddToPlannerBar(item: provider.comparison!.item),
    ),
  );

  Widget _buildResults(BuildContext context, PriceComparisonProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return AppStateWidget(
        icon: Icons.wifi_off_outlined,
        title: context.l10n.pricesUnavailable,
        message: provider.errorMessage!,
        actionLabel: context.l10n.retry,
        onAction: provider.retry,
      );
    }
    final comparison = provider.comparison;
    if (comparison == null || comparison.prices.isEmpty) {
      return AppStateWidget(
        icon: Icons.price_check_outlined,
        title: context.l10n.noPricesFound,
        message: context.l10n.noPricesMatchFilters,
        actionLabel: context.l10n.resetFilters,
        onAction: provider.resetFilters,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: comparison.prices.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          final premiseCode = comparison.cheapestOption?.premiseCode;
          return Column(
            children: [
              Row(
                children: [
                  ItemImage(
                    itemCode: comparison.item.itemCode,
                    itemName: comparison.item.itemName,
                    category: comparison.item.itemCategory,
                    group: comparison.item.itemGroup,
                    width: 62,
                    height: 62,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comparison.item.itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(comparison.item.unit),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BestPriceSummaryWidget(
                comparison: comparison,
                onViewStore: premiseCode == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StoreDetailScreen.fromPremiseCode(
                            premiseCode: premiseCode,
                          ),
                        ),
                      ),
              ),
            ],
          );
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.premisePricesCount(comparison.prices.length),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          );
        }
        final priceIndex = index - 2;
        final price = comparison.prices[priceIndex];
        final premiseCode = price.premiseCode;
        return ComparisonPriceCardWidget(
          price: price,
          rank: priceIndex + 1,
          onViewStore: premiseCode == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StoreDetailScreen.fromPremiseCode(
                      premiseCode: premiseCode,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.provider});
  final PriceComparisonProvider provider;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Column(
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('state-${provider.selectedState}'),
          initialValue: provider.selectedState ?? '',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.state,
            prefixIcon: const Icon(Icons.map_outlined),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(context.l10n.allStates)),
            ...PriceComparisonProvider.states.map(
              (state) => DropdownMenuItem(value: state, child: Text(state)),
            ),
          ],
          onChanged: provider.isLoading
              ? null
              : (value) => provider.selectState(
                  value == null || value.isEmpty ? null : value,
                ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'district-${provider.selectedState}-${provider.selectedDistrict}',
          ),
          initialValue: provider.selectedDistrict ?? '',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.district,
            prefixIcon: const Icon(Icons.location_city_outlined),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(context.l10n.allDistricts)),
            ...provider.districts.map(
              (district) => DropdownMenuItem(
                value: district,
                child: Text(district, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: provider.selectedState == null || provider.isLoading
              ? null
              : (value) => provider.selectDistrict(
                  value == null || value.isEmpty ? null : value,
                ),
        ),
        if (provider.selectedState != null || provider.selectedDistrict != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: provider.isLoading ? null : provider.resetFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: Text(context.l10n.resetFilters),
            ),
          ),
      ],
    ),
  );
}

class _AddToPlannerBar extends StatefulWidget {
  const _AddToPlannerBar({required this.item});
  final Item item;

  @override
  State<_AddToPlannerBar> createState() => _AddToPlannerBarState();
}

class _AddToPlannerBarState extends State<_AddToPlannerBar> {
  bool _saving = false;

  Future<void> _add() async {
    final auth = Provider.of<AuthProvider?>(context, listen: false);
    if (auth?.isAuthenticated != true) {
      final login = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.loginToUsePlanner),
          content: Text(context.l10n.plannerSaveNote),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.login),
            ),
          ],
        ),
      );
      if (login == true && mounted) {
        await Navigator.of(context)
            .push<void>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }

    final planner = Provider.of<PlannerProvider?>(context, listen: false);
    if (planner == null) return;
    if (planner.overview == null && !planner.isLoading) await planner.load();
    if (!mounted) return;
    final lists = planner.overview?.lists ?? const [];
    if (lists.isEmpty) {
      final openPlanner = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.createListFirst),
          content: Text(context.l10n.plannerNeedsList),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.openPlanner),
            ),
          ],
        ),
      );
      if (openPlanner == true && mounted) {
        await Navigator.of(
          context,
        ).push<void>(MaterialPageRoute(builder: (_) => const PlannerScreen()));
      }
      return;
    }

    var listId = lists.first.shoppingListId;
    if (lists.length > 1) {
      final selected = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        builder: (context) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            ListTile(title: Text(context.l10n.chooseShoppingList)),
            ...lists.map(
              (list) => ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text(list.name),
                onTap: () => Navigator.pop(context, list.shoppingListId),
              ),
            ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      listId = selected;
    }

    setState(() => _saving = true);
    try {
      await context.read<ApiService>().addShoppingListItem(
        listId,
        widget.item.itemCode,
        1,
      );
      await planner.load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.addedToShoppingList)),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _add,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart_rounded),
              label: Text(context.l10n.addToPlanner),
            ),
          ),
        ),
      ),
    ),
  );
}
