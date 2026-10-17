import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/best_places_models.dart';
import '../providers/app_location_provider.dart';
import '../providers/best_places_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/item_image_widget.dart';
import '../widgets/mobile_content.dart';
import 'store_detail_screen.dart';

class BestPlacesScreen extends StatelessWidget {
  const BestPlacesScreen({required this.listId, super.key});
  final String listId;

  @override
  Widget build(BuildContext context) {
    final location = Provider.of<AppLocationProvider?>(
      context,
      listen: false,
    )?.userLocation;
    final initialFilters = location == null
        ? const BestPlacesFilters()
        : BestPlacesFilters(
            latitude: location.latitude,
            longitude: location.longitude,
            radiusKm: 10,
          );
    return ChangeNotifierProvider(
      create: (context) => BestPlacesProvider(
        context.read<ApiService>(),
        listId,
        initialFilters: initialFilters,
      )..load(),
      child: const _BestPlacesView(),
    );
  }
}

class _BestPlacesView extends StatefulWidget {
  const _BestPlacesView();

  @override
  State<_BestPlacesView> createState() => _BestPlacesViewState();
}

class _BestPlacesViewState extends State<_BestPlacesView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) {
      context.read<BestPlacesProvider>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<BestPlacesProvider>(
    builder: (context, provider, _) => Scaffold(
      appBar: AppBar(title: const Text('Compare basket prices')),
      body: MobileContent(child: _buildBody(context, provider)),
    ),
  );

  Widget _buildBody(BuildContext context, BestPlacesProvider provider) {
    final data = provider.response;
    if (provider.isLoading && data == null) return const _LoadingList();
    if (provider.errorMessage != null && data == null) {
      final expired =
          provider.errorCode == 'AUTH_REQUIRED' ||
          provider.errorCode == 'INVALID_TOKEN' ||
          provider.errorCode == 'TOKEN_EXPIRED';
      return AppStateWidget(
        icon: expired ? Icons.lock_clock_outlined : Icons.wifi_off_outlined,
        title: expired
            ? 'Your session has expired'
            : "Couldn't compare basket prices",
        message: expired
            ? 'Log in again from Profile to compare your shopping list.'
            : provider.errorMessage!,
        actionLabel: expired ? 'Go back' : 'Try again',
        onAction: expired ? () => Navigator.pop(context) : provider.refresh,
      );
    }
    if (data == null) return const SizedBox.shrink();
    if (data.hasNoActiveItems) {
      return const AppStateWidget(
        icon: Icons.check_circle_outline,
        title: 'No active items to compare',
        message: 'Completed items are excluded. Add or reopen an item first.',
      );
    }
    if (data.hasNoPriceData) {
      return AppStateWidget(
        icon: Icons.price_check_outlined,
        title: 'No price records available',
        message:
            'No imported premise prices were found for these active items.',
        actionLabel: 'Try again',
        onAction: provider.refresh,
      );
    }

    int? bestPricePremiseCode;
    for (final store in provider.stores) {
      if (store.isComplete &&
          data.summary.lowestCompleteTotal != null &&
          (store.basketTotal! - data.summary.lowestCompleteTotal!).abs() <
              0.005) {
        bestPricePremiseCode = store.premiseCode;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _ComparisonSummary(data: data),
          const SizedBox(height: 12),
          _LocationRadiusFilter(
            provider: provider,
            onRequestLocation: () => _requestLocation(context, provider),
          ),
          const SizedBox(height: 12),
          _FilterBar(
            provider: provider,
            options: data.filterOptions,
            onOpen: () => _showFilters(context, provider, data.filterOptions),
          ),
          if (!provider.filters.isDefault) ...[
            const SizedBox(height: 8),
            _ActiveFilters(provider: provider),
          ],
          if (data.twoStoreCombination != null) ...[
            const SizedBox(height: 14),
            _TwoStoreCard(combination: data.twoStoreCombination!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Shop comparison',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${data.pagination.totalResults} results',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          if (!provider.isLoading && provider.stores.isEmpty)
            AppStateWidget(
              compact: true,
              icon: Icons.filter_alt_off_outlined,
              title: 'No shops match these filters',
              message: 'Reset the filters to see more basket comparisons.',
              actionLabel: 'Reset filters',
              onAction: provider.resetFilters,
            )
          else
            for (var index = 0; index < provider.stores.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BasketStoreCard(
                  rank: index + 1,
                  store: provider.stores[index],
                  isBestPrice:
                      provider.stores[index].premiseCode ==
                      bestPricePremiseCode,
                  bestTotal: data.summary.lowestCompleteTotal,
                  onViewStore: () =>
                      _openStore(context, provider.stores[index].premiseCode),
                ),
              ),
          if (provider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.errorMessage != null && provider.stores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: provider.loadNextPage,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry loading more shops'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _requestLocation(
    BuildContext context,
    BestPlacesProvider provider,
  ) async {
    final locationProvider = Provider.of<AppLocationProvider?>(
      context,
      listen: false,
    );
    if (locationProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location is unavailable on this device.'),
        ),
      );
      return;
    }
    final result = await locationProvider.requestCurrentLocation();
    if (!context.mounted) return;
    final location = result.location;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location could not be obtained. Check permission or choose an area in filters.',
          ),
        ),
      );
      return;
    }
    await provider.useLocation(location.latitude, location.longitude);
  }

  Future<void> _showFilters(
    BuildContext context,
    BestPlacesProvider provider,
    BestPlacesFilterOptions options,
  ) async {
    var coverage = provider.filters.coverage;
    var sort = provider.filters.sort;
    var state = provider.filters.state;
    var district = provider.filters.district;
    final maxController = TextEditingController(
      text: provider.filters.maxTotal?.toStringAsFixed(2) ?? '',
    );
    String? amountError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final districts =
              options.districts
                  .where((value) => state == null || value.state == state)
                  .map((value) => value.district)
                  .toSet()
                  .toList()
                ..sort();
          if (district != null && !districts.contains(district)) {
            district = null;
          }
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filter shops',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                const Text('Coverage'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BestPlacesCoverage.values
                      .map(
                        (value) => ChoiceChip(
                          label: Text(value.label),
                          selected: coverage == value,
                          onSelected: (_) =>
                              setSheetState(() => coverage = value),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<BestPlacesSort>(
                  initialValue: sort,
                  decoration: const InputDecoration(labelText: 'Sort'),
                  items: BestPlacesSort.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setSheetState(() => sort = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: state,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All states'),
                    ),
                    ...options.states.map(
                      (value) => DropdownMenuItem<String?>(
                        value: value,
                        child: Text(value),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() {
                    state = value;
                    district = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: district,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All districts'),
                    ),
                    ...districts.map(
                      (value) => DropdownMenuItem<String?>(
                        value: value,
                        child: Text(value),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => district = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Maximum complete basket total (RM)',
                    errorText: amountError,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheetState(() {
                          coverage = BestPlacesCoverage.all;
                          sort = BestPlacesSort.priceAsc;
                          state = null;
                          district = null;
                          maxController.clear();
                          amountError = null;
                        }),
                        child: const Text('Reset filters'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final text = maxController.text.trim();
                          final amount = text.isEmpty
                              ? null
                              : double.tryParse(text);
                          if (text.isNotEmpty &&
                              (amount == null || amount <= 0)) {
                            setSheetState(() {
                              amountError = 'Enter a positive RM amount';
                            });
                            return;
                          }
                          Navigator.pop(sheetContext);
                          provider.applyFilters(
                            BestPlacesFilters(
                              coverage: coverage,
                              sort: sort,
                              state: state,
                              district: district,
                              maxTotal: amount,
                              latitude: provider.filters.latitude,
                              longitude: provider.filters.longitude,
                              radiusKm: provider.filters.radiusKm,
                            ),
                          );
                        },
                        child: const Text('Apply filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    // The modal route can still animate one final frame after its result is
    // delivered. Dispose after that animation so the TextField never observes
    // an already-disposed controller.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    maxController.dispose();
  }

  void _openStore(BuildContext context, int premiseCode) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/premises/$premiseCode',
          arguments: premiseCode,
        ),
        builder: (_) =>
            StoreDetailScreen.fromPremiseCode(premiseCode: premiseCode),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const LinearProgressIndicator(),
      const SizedBox(height: 16),
      Text(
        'Comparing your basket across shops...',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 20),
      for (var index = 0; index < 3; index++)
        Card(
          child: SizedBox(
            height: 150,
            child: Center(
              child: Icon(
                Icons.storefront_outlined,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
    ],
  );
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({required this.data});
  final BestPlacesResponse data;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final hasComplete = summary.completePremises > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F5EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.itemCount} ${data.itemCount == 1 ? 'item' : 'items'}',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            hasComplete
                ? '${summary.completePremises} shops have all ${data.itemCount} items'
                : 'No single shop has all ${data.itemCount} items',
          ),
          const SizedBox(height: 3),
          Text(
            hasComplete
                ? 'Lowest complete basket: ${_rm(summary.lowestCompleteTotal!)}'
                : 'Showing shops with the highest coverage',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRadiusFilter extends StatelessWidget {
  const _LocationRadiusFilter({
    required this.provider,
    required this.onRequestLocation,
  });

  final BestPlacesProvider provider;
  final VoidCallback onRequestLocation;

  @override
  Widget build(BuildContext context) {
    final filters = provider.filters;
    if (!filters.hasLocation) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.near_me_outlined),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Use your location to compare the cheapest baskets nearby.',
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: provider.isLoading ? null : onRequestLocation,
              child: const Text('Use location'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.my_location, size: 19),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Cheapest baskets near you',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 10, label: Text('10 km')),
            ButtonSegment(value: 25, label: Text('25 km')),
            ButtonSegment(value: 50, label: Text('50 km')),
          ],
          selected: {filters.radiusKm ?? 10},
          onSelectionChanged: provider.isLoading
              ? null
              : (value) => provider.setRadius(value.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.provider,
    required this.options,
    required this.onOpen,
  });

  final BestPlacesProvider provider;
  final BestPlacesFilterOptions options;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.filter_list, size: 18),
          label: const Text('Filter shops'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.sort, size: 18),
          label: Text(provider.filters.sort.label),
        ),
      ),
    ],
  );
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.provider});
  final BestPlacesProvider provider;

  @override
  Widget build(BuildContext context) {
    final filters = provider.filters;
    BestPlacesFilters update({
      BestPlacesCoverage? coverage,
      BestPlacesSort? sort,
      String? state,
      bool clearState = false,
      String? district,
      bool clearDistrict = false,
      double? maxTotal,
      bool clearMax = false,
      double? latitude,
      double? longitude,
      int? radiusKm,
      bool clearLocation = false,
    }) => BestPlacesFilters(
      coverage: coverage ?? filters.coverage,
      sort: sort ?? filters.sort,
      state: clearState ? null : state ?? filters.state,
      district: clearDistrict ? null : district ?? filters.district,
      maxTotal: clearMax ? null : maxTotal ?? filters.maxTotal,
      latitude: clearLocation ? null : latitude ?? filters.latitude,
      longitude: clearLocation ? null : longitude ?? filters.longitude,
      radiusKm: clearLocation ? null : radiusKm ?? filters.radiusKm,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (filters.coverage != BestPlacesCoverage.all)
            _RemovableChip(
              label: filters.coverage.label,
              onRemoved: () => provider.applyFilters(
                update(coverage: BestPlacesCoverage.all),
              ),
            ),
          if (filters.sort != BestPlacesSort.priceAsc)
            _RemovableChip(
              label: filters.sort.label,
              onRemoved: () =>
                  provider.applyFilters(update(sort: BestPlacesSort.priceAsc)),
            ),
          if (filters.state != null)
            _RemovableChip(
              label: filters.state!,
              onRemoved: () => provider.applyFilters(
                update(clearState: true, clearDistrict: true),
              ),
            ),
          if (filters.district != null)
            _RemovableChip(
              label: filters.district!,
              onRemoved: () =>
                  provider.applyFilters(update(clearDistrict: true)),
            ),
          if (filters.maxTotal != null)
            _RemovableChip(
              label: 'Up to ${_rm(filters.maxTotal!)}',
              onRemoved: () => provider.applyFilters(update(clearMax: true)),
            ),
          if (filters.hasLocation)
            _RemovableChip(
              label: 'Within ${filters.radiusKm ?? 10} km',
              onRemoved: () =>
                  provider.applyFilters(update(clearLocation: true)),
            ),
        ],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemoved});
  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InputChip(label: Text(label), onDeleted: onRemoved),
  );
}

class _BasketStoreCard extends StatefulWidget {
  const _BasketStoreCard({
    required this.rank,
    required this.store,
    required this.isBestPrice,
    required this.bestTotal,
    required this.onViewStore,
  });

  final int rank;
  final BasketStore store;
  final bool isBestPrice;
  final double? bestTotal;
  final VoidCallback onViewStore;

  @override
  State<_BasketStoreCard> createState() => _BasketStoreCardState();
}

class _BasketStoreCardState extends State<_BasketStoreCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final colors = Theme.of(context).colorScheme;
    final isBest = widget.isBestPrice;
    final difference = store.isComplete && widget.bestTotal != null
        ? store.basketTotal! - widget.bestTotal!
        : null;
    return Material(
      color: store.isComplete ? colors.surface : const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isBest ? colors.primary : colors.outlineVariant,
          width: isBest ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: store.isComplete
                        ? colors.primaryContainer
                        : const Color(0xFFFFE082),
                    child: Text(
                      '#${widget.rank}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isBest)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: _BestBadge(),
                          ),
                        Text(
                          store.premiseName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_titleCase(store.premiseType)} | ${store.district}, ${store.state}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (store.distanceKm case final distance?) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      store.isComplete
                          ? 'All ${store.totalItemCount} items available'
                          : '${store.coveredItemCount} of ${store.totalItemCount} items available',
                      style: TextStyle(
                        color: store.isComplete ? colors.primary : colors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        store.isComplete ? 'BASKET TOTAL' : 'PARTIAL TOTAL',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        _rm(store.displayedTotal!),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: store.isComplete
                              ? colors.primary
                              : colors.error,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (difference != null && difference > 0.005)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_rm(difference)} more than best',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (_expanded) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                for (final item in store.items) _BasketItemRow(item: item),
                if (store.missingItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Missing',
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  for (final item in store.missingItems)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${item.itemName} x${_quantity(item.requestedQuantity)}',
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onViewStore,
                        icon: const Icon(Icons.storefront_outlined, size: 18),
                        label: const Text('View store'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onViewStore,
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: const Text('Navigate'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BestBadge extends StatelessWidget {
  const _BestBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'BEST PRICE',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _BasketItemRow extends StatelessWidget {
  const _BasketItemRow({required this.item});
  final BasketStoreItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ItemImage(
          itemCode: item.itemCode,
          itemName: item.itemName,
          category: '',
          width: 42,
          height: 42,
          borderRadius: 10,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.itemName, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(
                '${_rm(item.unitPrice)} x ${_quantity(item.requestedQuantity)} | ${_date(item.priceDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _rm(item.lineTotal),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _TwoStoreCard extends StatelessWidget {
  const _TwoStoreCard({required this.combination});
  final TwoStoreCombination combination;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F8F3),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.alt_route_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text(
        'Cheapest two-store combination',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text('Complete basket: ${_rm(combination.basketTotal)}'),
      children: [
        if (combination.savingVsBestSingle != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Save ${_rm(combination.savingVsBestSingle!)} compared with the best single store',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        for (final store in combination.stores)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.premiseName} | ${_rm(store.itemTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                for (final item in store.items)
                  Text(
                    '${item.itemName} x${_quantity(item.requestedQuantity)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

String _rm(double value) => 'RM${value.toStringAsFixed(2)}';

String _quantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

String _date(String value) {
  final parts = value.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
}

String _titleCase(String value) => value
    .toLowerCase()
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
