import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/premise.dart';
import '../l10n/l10n.dart';
import '../providers/item_provider.dart';
import '../providers/planner_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/item_list_tile_widget.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/mobile_content.dart';
import 'item_detail_screen.dart';
import 'price_comparison_screen.dart';
import 'price_trend_screen.dart';
import 'shopping_list_screen.dart';

enum SearchDestination { itemDetail, comparison, trend }

String _searchCategoryLabel(BuildContext context, String? key) =>
    switch (key) {
      'chicken' => context.l10n.searchChicken,
      'meat' => context.l10n.searchMeat,
      'eggs' => context.l10n.searchEggs,
      'vegetables' => context.l10n.searchVegetables,
      'fruits' => context.l10n.searchFruits,
      'drinks' => context.l10n.searchDrinks,
      'dry-goods' => context.l10n.searchDryGoods,
      'baby' => context.l10n.searchBaby,
      'household' => context.l10n.searchHousehold,
      _ => context.l10n.searchAll,
    };

const _searchCategories = <(String, String?)>[
  ('All', null),
  ('Chicken', 'chicken'),
  ('Meat', 'meat'),
  ('Eggs', 'eggs'),
  ('Vegetables', 'vegetables'),
  ('Fruits', 'fruits'),
  ('Drinks', 'drinks'),
  ('Dry Goods', 'dry-goods'),
  ('Baby', 'baby'),
  ('Household', 'household'),
];

class SearchScreen extends StatelessWidget {
  const SearchScreen({
    this.initialCategory,
    this.destination = SearchDestination.itemDetail,
    super.key,
  });

  final String? initialCategory;
  final SearchDestination destination;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        ItemProvider(context.read<ApiService>())
          ..setFilters(category: initialCategory),
    child: _SearchContent(destination: destination),
  );
}

class _SearchContent extends StatefulWidget {
  const _SearchContent({required this.destination});
  final SearchDestination destination;

  @override
  State<_SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<_SearchContent> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
  }

  void _loadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 260) {
      context.read<ItemProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _openItem(Item item) {
    final Widget screen = switch (widget.destination) {
      SearchDestination.itemDetail => ItemDetailScreen(itemCode: item.itemCode),
      SearchDestination.comparison => PriceComparisonScreen(
        itemCode: item.itemCode,
      ),
      SearchDestination.trend => PriceTrendScreen(itemCode: item.itemCode),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _showFilters(ItemProvider provider) async {
    final filters = await showModalBottomSheet<_AppliedItemFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ItemFilterSheet(
        apiService: context.read<ApiService>(),
        category: provider.category,
        state: provider.state,
        district: provider.district,
        hasAvailablePrices: provider.hasAvailablePrices,
      ),
    );
    if (filters == null || !mounted) return;
    provider.applyFilters(
      category: filters.category,
      state: filters.state,
      district: filters.district,
      hasAvailablePrices: filters.hasAvailablePrices,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeList = context
        .watch<PlannerProvider?>()
        ?.overview
        ?.lists
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(context.l10n.searchTitle),
        actions: [
          if (activeList != null)
            IconButton(
              tooltip: context.l10n.openShoppingList(activeList.name),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ShoppingListScreen(listId: activeList.shoppingListId),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
        ],
      ),
      body: MobileContent(
        child: Consumer<ItemProvider>(
          builder: (context, provider, _) => Column(
            children: [
              _buildSearchField(provider),
              _buildCategoryChips(provider),
              if (provider.state != null ||
                  provider.district != null ||
                  provider.hasAvailablePrices)
                _buildActiveFilters(provider),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        provider.query.isEmpty
                            ? context.l10n.browseItems
                            : context.l10n.results,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      context.l10n.itemCount(provider.total),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildResults(provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ItemProvider provider) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(
      children: [
        TextField(
          key: const ValueKey('item-search-field'),
          controller: _searchController,
          autofocus: true,
          onChanged: (value) {
            setState(() {});
            provider.search(value);
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.homeSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.clearSearch,
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      provider.clearSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        SizedBox(
          height: 2,
          child: provider.isLoading
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  Widget _buildCategoryChips(ItemProvider provider) => Padding(
    padding: const EdgeInsets.only(left: 16, right: 8),
    child: SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _categoryScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 3,
              radius: const Radius.circular(8),
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  controller: _categoryScrollController,
                  key: const ValueKey('search-category-chips'),
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _searchCategories[index];
                    final selected = provider.category == category.$2;
                    return FilterChip(
                      key: ValueKey('category-${category.$2 ?? 'all'}'),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: JimatMyColors.green,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? JimatMyColors.green
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : JimatMyColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      label: Text(_searchCategoryLabel(context, category.$2)),
                      onSelected: (_) {
                        provider.selectCategory(category.$2);
                        if (!_categoryScrollController.hasClients) return;
                        _categoryScrollController.animateTo(
                          (index * 90).toDouble().clamp(
                            0,
                            _categoryScrollController.position.maxScrollExtent,
                          ),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            key: const ValueKey('open-item-filters'),
            tooltip: context.l10n.filterItems,
            onPressed: () => _showFilters(provider),
            icon: Badge(
              isLabelVisible:
                  provider.state != null ||
                  provider.district != null ||
                  provider.hasAvailablePrices,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildActiveFilters(ItemProvider provider) => SizedBox(
    height: 38,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      children: [
        if (provider.state != null) _ActiveFilterChip(label: provider.state!),
        if (provider.district != null)
          _ActiveFilterChip(label: provider.district!),
        if (provider.hasAvailablePrices)
          _ActiveFilterChip(label: context.l10n.pricesAvailable),
      ],
    ),
  );

  Widget _buildResults(ItemProvider provider) {
    if (provider.isLoading) {
      if (provider.items.isEmpty) return const _SearchLoadingSkeleton();
    }
    if (provider.errorMessage != null && provider.items.isEmpty) {
      return AppStateWidget(
        icon: Icons.wifi_off_outlined,
        title: context.l10n.itemsUnavailable,
        message: provider.errorMessage!,
        actionLabel: context.l10n.retry,
        onAction: provider.retry,
      );
    }
    if (provider.items.isEmpty) {
      return AppStateWidget(
        icon: Icons.search_off_rounded,
        title: provider.query.isEmpty
            ? context.l10n.noGroceries
            : context.l10n.noMatchingGroceries,
        message: context.l10n.searchEmptyMessage,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.retry,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 106),
        itemBuilder: (context, index) {
          if (index == provider.items.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: provider.isLoadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: provider.loadMore,
                        child: Text(context.l10n.loadMore),
                      ),
              ),
            );
          }
          final item = provider.items[index];
          return ItemListTileWidget(
            key: ValueKey('search-item-${item.itemCode}'),
            item: item,
            onTap: () => _openItem(item),
          );
        },
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: Chip(
      avatar: const Icon(Icons.check_circle_outline_rounded, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: JimatMyColors.mint,
      side: BorderSide.none,
    ),
  );
}

class _SearchLoadingSkeleton extends StatelessWidget {
  const _SearchLoadingSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    key: const ValueKey('search-loading-skeleton'),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
    itemCount: 5,
    separatorBuilder: (_, _) => const Divider(height: 1, indent: 106),
    itemBuilder: (_, _) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: JimatMyColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(double.infinity),
                const SizedBox(height: 8),
                _skeletonLine(92),
                const SizedBox(height: 8),
                _skeletonLine(126),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _skeletonLine(double width) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: const Color(0xFFE5EAE6),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _AppliedItemFilters {
  const _AppliedItemFilters({
    required this.category,
    required this.state,
    required this.district,
    required this.hasAvailablePrices,
  });

  final String? category;
  final String? state;
  final String? district;
  final bool hasAvailablePrices;
}

class _ItemFilterSheet extends StatefulWidget {
  const _ItemFilterSheet({
    required this.apiService,
    required this.category,
    required this.state,
    required this.district,
    required this.hasAvailablePrices,
  });

  final ApiService apiService;
  final String? category;
  final String? state;
  final String? district;
  final bool hasAvailablePrices;

  @override
  State<_ItemFilterSheet> createState() => _ItemFilterSheetState();
}

class _ItemFilterSheetState extends State<_ItemFilterSheet> {
  late String? _category = widget.category;
  late String? _state = widget.state;
  late String? _district = widget.district;
  late bool _hasAvailablePrices = widget.hasAvailablePrices;
  late final Future<List<PremiseFilterGroup>> _locationFilters = widget
      .apiService
      .getPremiseFilters();

  void _reset() => setState(() {
    _category = null;
    _state = null;
    _district = null;
    _hasAvailablePrices = true;
  });

  void _apply() => Navigator.of(context).pop(
    _AppliedItemFilters(
      category: _category,
      state: _state,
      district: _district,
      hasAvailablePrices: _hasAvailablePrices,
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.filterItems,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('sheet-category-$_category'),
                initialValue: _category ?? '',
                decoration: InputDecoration(labelText: context.l10n.category),
                isExpanded: true,
                items: _searchCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.$2 ?? '',
                        child: Text(_searchCategoryLabel(context, category.$2)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(
                  () =>
                      _category = value == null || value.isEmpty ? null : value,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<PremiseFilterGroup>>(
                future: _locationFilters,
                builder: (context, snapshot) {
                  final groups = snapshot.data ?? const <PremiseFilterGroup>[];
                  final selectedGroup = groups
                      .where((group) => group.state == _state)
                      .firstOrNull;
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey('sheet-state-$_state'),
                        initialValue: _state ?? '',
                        decoration: InputDecoration(labelText: context.l10n.state),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text(context.l10n.allStates),
                          ),
                          ...groups.map(
                            (group) => DropdownMenuItem<String>(
                              value: group.state,
                              child: Text(group.state),
                            ),
                          ),
                        ],
                        onChanged: snapshot.hasData
                            ? (value) => setState(() {
                                _state = value == null || value.isEmpty
                                    ? null
                                    : value;
                                _district = null;
                              })
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('sheet-district-$_district'),
                        initialValue: _district ?? '',
                        decoration: InputDecoration(
                          labelText: context.l10n.district,
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Text(context.l10n.allDistricts),
                          ),
                          ...?selectedGroup?.districts.map(
                            (district) => DropdownMenuItem<String>(
                              value: district,
                              child: Text(district),
                            ),
                          ),
                        ],
                        onChanged: selectedGroup == null
                            ? null
                            : (value) => setState(
                                () => _district = value == null || value.isEmpty
                                    ? null
                                    : value,
                              ),
                      ),
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            context.l10n.locationFiltersUnavailable,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.hasAvailablePricesTitle),
                subtitle: Text(context.l10n.hasAvailablePricesSubtitle),
                value: _hasAvailablePrices,
                onChanged: (value) =>
                    setState(() => _hasAvailablePrices = value),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _apply,
                child: Text(context.l10n.applyFilters),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(context.l10n.resetFilters),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
