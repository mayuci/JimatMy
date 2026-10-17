import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/premise.dart';
import '../providers/app_location_provider.dart';
import '../providers/nearby_premises_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/maps_config_service.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/location_onboarding_widget.dart';
import '../widgets/premise_list_tile_widget.dart';
import '../widgets/premise_map_widget.dart';
import 'store_detail_screen.dart';

enum NearbyViewMode { map, list }

class NearbyStoresScreen extends StatelessWidget {
  const NearbyStoresScreen({
    this.mapsConfigService,
    this.mapFactory,
    this.mapCreationTimeout = const Duration(seconds: 8),
    super.key,
  });

  final MapsConfigService? mapsConfigService;
  final PremiseMapFactory? mapFactory;
  final Duration mapCreationTimeout;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => NearbyPremisesProvider(
      context.read<ApiService>(),
      context.read<AppLocationProvider>(),
    ),
    child: _NearbyStoresView(
      mapsConfigService: mapsConfigService,
      mapFactory: mapFactory,
      mapCreationTimeout: mapCreationTimeout,
    ),
  );
}

class _NearbyStoresView extends StatefulWidget {
  const _NearbyStoresView({
    required this.mapsConfigService,
    required this.mapFactory,
    required this.mapCreationTimeout,
  });

  final MapsConfigService? mapsConfigService;
  final PremiseMapFactory? mapFactory;
  final Duration mapCreationTimeout;

  @override
  State<_NearbyStoresView> createState() => _NearbyStoresViewState();
}

class _NearbyStoresViewState extends State<_NearbyStoresView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  NearbyPremisesProvider? _provider;
  AppLocationProvider? _location;
  NearbyViewMode _viewMode = NearbyViewMode.list;
  int? _selectedPremiseCode;
  bool _initialLoadScheduled = false;
  bool _locationActionInProgress = false;
  bool _browseWithoutLocation = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<NearbyPremisesProvider>();
    final location = context.read<AppLocationProvider>();
    if (!identical(_location, location)) {
      _location?.removeListener(_handleLocationState);
      _location = location..addListener(_handleLocationState);
    }
    _provider = provider;
    _handleLocationState();
  }

  void _handleLocationState() {
    final provider = _provider;
    final location = _location;
    if (provider == null ||
        location == null ||
        !location.isInitialized ||
        provider.isLoading ||
        _initialLoadScheduled ||
        _locationActionInProgress) {
      return;
    }
    final hasArea =
        location.userLocation != null ||
        location.manualState != null ||
        _browseWithoutLocation;
    if (!hasArea || provider.hasLoaded) return;
    _initialLoadScheduled = true;
    _viewMode = location.userLocation == null
        ? NearbyViewMode.list
        : NearbyViewMode.map;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await provider.load();
        if (mounted &&
            location.userLocation != null &&
            provider.mappedPremises.isEmpty) {
          setState(() => _viewMode = NearbyViewMode.list);
        }
      } finally {
        _initialLoadScheduled = false;
      }
    });
  }

  @override
  void dispose() {
    _location?.removeListener(_handleLocationState);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final provider = context.read<NearbyPremisesProvider>();
    _locationActionInProgress = true;
    try {
      final result = await provider.useMyLocation();
      if (!mounted || result.location == null) return;
      setState(() {
        _browseWithoutLocation = false;
        _selectedPremiseCode = null;
      });
      if (!provider.hasLoaded) await provider.load();
      if (!mounted) return;
      setState(() {
        _viewMode = provider.mappedPremises.isEmpty
            ? NearbyViewMode.list
            : NearbyViewMode.map;
      });
    } finally {
      _locationActionInProgress = false;
    }
  }

  Future<void> _chooseAreaManually() async {
    _locationActionInProgress = true;
    try {
      await showManualLocationSelector(context);
      if (!mounted) return;
      final location = context.read<AppLocationProvider>();
      if (location.manualState == null) return;
      setState(() {
        _browseWithoutLocation = false;
        _viewMode = NearbyViewMode.list;
        _selectedPremiseCode = null;
      });
      await context.read<NearbyPremisesProvider>().useManualArea();
    } finally {
      _locationActionInProgress = false;
    }
  }

  Future<void> _browseAllStores() async {
    final provider = context.read<NearbyPremisesProvider>();
    _locationActionInProgress = true;
    try {
      setState(() {
        _browseWithoutLocation = true;
        _viewMode = NearbyViewMode.list;
        _selectedPremiseCode = null;
      });
      await provider.browseAllStores();
    } finally {
      _locationActionInProgress = false;
    }
  }

  Future<void> _showFilters(NearbyPremisesProvider provider) async {
    final filters = await showModalBottomSheet<_NearbyFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NearbyFilterSheet(provider: provider),
    );
    if (filters == null || !mounted) return;
    await provider.applyFilters(
      radiusKm: filters.radiusKm,
      retailers: filters.retailers,
      sortMode: filters.sortMode,
    );
  }

  @override
  Widget build(BuildContext context) =>
      Consumer2<NearbyPremisesProvider, AppLocationProvider>(
        builder: (context, provider, location, _) {
          final hasArea =
              location.userLocation != null ||
              location.manualState != null ||
              _browseWithoutLocation;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Nearby stores'),
              actions: [
                if (hasArea && provider.filters.isNotEmpty)
                  IconButton(
                    key: const ValueKey('nearby-filter-button'),
                    tooltip: 'Filter stores',
                    onPressed: provider.isLoading
                        ? null
                        : () => _showFilters(provider),
                    icon: const Icon(Icons.tune_rounded),
                  ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: !location.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : hasArea
                    ? _buildBrowsing(provider)
                    : _LocationConsent(
                        location: location,
                        onUseLocation: _useMyLocation,
                        onChooseManually: _chooseAreaManually,
                        onBrowseAll: _browseAllStores,
                      ),
              ),
            ),
          );
        },
      );

  Widget _buildBrowsing(NearbyPremisesProvider provider) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          key: const ValueKey('nearby-search-field'),
          controller: _searchController,
          onChanged: (value) {
            provider.search(value);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Search store name or address',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      provider.search('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<NearbyViewMode>(
            segments: const [
              ButtonSegment(
                value: NearbyViewMode.map,
                icon: Icon(Icons.map_outlined),
                label: Text('Map'),
              ),
              ButtonSegment(
                value: NearbyViewMode.list,
                icon: Icon(Icons.list_rounded),
                label: Text('List'),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selection) =>
                setState(() => _viewMode = selection.first),
          ),
        ),
      ),
      _StoreSummary(provider: provider, onUseLocation: _useMyLocation),
      _ActiveFilters(provider: provider),
      Expanded(child: _buildResults(provider)),
    ],
  );

  Widget _buildResults(NearbyPremisesProvider provider) {
    if (provider.isLoading && provider.premises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.premises.isEmpty) {
      return AppStateWidget(
        icon: Icons.wifi_off_outlined,
        title: 'Stores unavailable',
        message: provider.errorMessage!,
        actionLabel: 'Retry',
        onAction: provider.load,
      );
    }
    if (provider.premises.isEmpty) {
      final radius = provider.selectedRadiusKm;
      if (radius != null) {
        return AppStateWidget(
          icon: Icons.radio_button_checked_outlined,
          title: 'No stores found within ${radius.round()} km.',
          message:
              'Try increasing the distance or clearing the retailer filter.',
          actionLabel: 'Increase distance',
          onAction: () => _showFilters(provider),
        );
      }
      if (provider.userLocation != null && !provider.hasAnyPremises) {
        return AppStateWidget(
          icon: Icons.location_searching_rounded,
          title: 'Nearby distances are not ready',
          message:
              'No active stores have fresh verified locations yet. '
              'Refresh after the premise location cache is prepared.',
          actionLabel: 'Refresh',
          onAction: provider.load,
        );
      }
      return AppStateWidget(
        icon: Icons.storefront_outlined,
        title: 'No stores found',
        message: 'No premises match this search and filter selection.',
        actionLabel: 'Reset filters',
        onAction: provider.resetFilters,
      );
    }
    return _viewMode == NearbyViewMode.map
        ? _MapResults(
            provider: provider,
            selectedPremiseCode: _selectedPremiseCode,
            onSelect: (premise) =>
                setState(() => _selectedPremiseCode = premise.premiseCode),
            onOpen: _openStore,
            scrollController: _scrollController,
            mapsConfigService: widget.mapsConfigService,
            mapFactory: widget.mapFactory,
            mapCreationTimeout: widget.mapCreationTimeout,
          )
        : _PremiseList(
            provider: provider,
            selectedPremiseCode: _selectedPremiseCode,
            onOpen: _openStore,
            scrollController: _scrollController,
          );
  }

  void _openStore(Premise premise) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => StoreDetailScreen(
        premise: premise,
        userLocation: context.read<NearbyPremisesProvider>().userLocation,
      ),
    ),
  );
}

class _LocationConsent extends StatelessWidget {
  const _LocationConsent({
    required this.location,
    required this.onUseLocation,
    required this.onChooseManually,
    required this.onBrowseAll,
  });

  final AppLocationProvider location;
  final Future<void> Function() onUseLocation;
  final Future<void> Function() onChooseManually;
  final Future<void> Function() onBrowseAll;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
    child: Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on_rounded,
            size: 46,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Find stores near you',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Allow location access to show nearby supermarkets and their distance from you.',
          textAlign: TextAlign.center,
        ),
        if (location.failure case final failure?) ...[
          const SizedBox(height: 18),
          _LocationFailureCard(
            failure: failure,
            onTryAgain: onUseLocation,
            onOpenSettings: location.openAppSettings,
            onOpenLocationSettings: location.openLocationSettings,
          ),
        ],
        if (location.failure != null) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            key: const ValueKey('nearby-browse-all'),
            onPressed: location.isRequesting ? null : onBrowseAll,
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Browse stores without location'),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('nearby-use-location'),
            onPressed: location.isRequesting ? null : onUseLocation,
            icon: location.isRequesting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              location.isRequesting
                  ? 'Finding your location...'
                  : 'Use my location',
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('nearby-choose-area'),
            onPressed: location.isRequesting ? null : onChooseManually,
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('Choose area manually'),
          ),
        ),
      ],
    ),
  );
}

class _LocationFailureCard extends StatelessWidget {
  const _LocationFailureCard({
    required this.failure,
    required this.onTryAgain,
    required this.onOpenSettings,
    required this.onOpenLocationSettings,
  });

  final LocationFailure failure;
  final VoidCallback onTryAgain;
  final Future<bool> Function() onOpenSettings;
  final Future<bool> Function() onOpenLocationSettings;

  String get message => switch (failure) {
    LocationFailure.denied =>
      'Location permission was denied. Try again or choose an area manually.',
    LocationFailure.deniedForever =>
      kIsWeb
          ? 'Location is blocked. Allow it in your browser site settings, then try again.'
          : 'Location permission is blocked. Open settings or choose an area manually.',
    LocationFailure.serviceDisabled =>
      'Location services are turned off. Turn them on to find nearby stores.',
    LocationFailure.timeout =>
      'Your location took too long to respond. You can try again.',
    LocationFailure.unavailable =>
      kIsWeb
          ? 'Location is unavailable. Check browser permissions and use localhost or HTTPS.'
          : 'Your location is currently unavailable.',
  };

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: 8),
        if (failure == LocationFailure.deniedForever && !kIsWeb)
          TextButton(
            onPressed: onOpenSettings,
            child: const Text('Open settings'),
          )
        else if (failure == LocationFailure.serviceDisabled && !kIsWeb)
          TextButton(
            onPressed: onOpenLocationSettings,
            child: const Text('Turn on location services'),
          )
        else
          TextButton(onPressed: onTryAgain, child: const Text('Try again')),
      ],
    ),
  );
}

class _MapResults extends StatelessWidget {
  const _MapResults({
    required this.provider,
    required this.selectedPremiseCode,
    required this.onSelect,
    required this.onOpen,
    required this.scrollController,
    required this.mapsConfigService,
    required this.mapFactory,
    required this.mapCreationTimeout,
  });

  final NearbyPremisesProvider provider;
  final int? selectedPremiseCode;
  final ValueChanged<Premise> onSelect;
  final ValueChanged<Premise> onOpen;
  final ScrollController scrollController;
  final MapsConfigService? mapsConfigService;
  final PremiseMapFactory? mapFactory;
  final Duration mapCreationTimeout;

  @override
  Widget build(BuildContext context) {
    Premise? selected;
    for (final premise in provider.mappedPremises) {
      if (premise.premiseCode == selectedPremiseCode) selected = premise;
    }
    selected ??= provider.mappedPremises.isEmpty
        ? null
        : provider.mappedPremises.first;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            key: const ValueKey('nearby-map-container'),
            height: 230,
            width: double.infinity,
            child: provider.mappedPremises.isEmpty
                ? const AppStateWidget(
                    icon: Icons.location_off_outlined,
                    title: 'No store map locations',
                    message:
                        'Map locations are not available for these stores. '
                        'Switch to List to browse them.',
                    compact: true,
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      PremiseMapWidget(
                        premises: provider.mappedPremises,
                        selectedPremise: selected,
                        userLocation: provider.userLocation,
                        compact: true,
                        showRecenterButton: true,
                        centerOnUserLocation: true,
                        onPremiseSelected: onSelect,
                        mapsConfigService: mapsConfigService,
                        mapFactory: mapFactory,
                        mapCreationTimeout: mapCreationTimeout,
                      ),
                      if (selected case final store?)
                        if (selectedPremiseCode != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 10,
                            child: _SelectedStoreCard(
                              premise: store,
                              onViewStore: () => onOpen(store),
                            ),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _PremiseList(
            provider: provider,
            selectedPremiseCode: selectedPremiseCode,
            onOpen: onOpen,
            scrollController: scrollController,
          ),
        ),
      ],
    );
  }
}

class _SelectedStoreCard extends StatelessWidget {
  const _SelectedStoreCard({required this.premise, required this.onViewStore});

  final Premise premise;
  final VoidCallback onViewStore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final distance = premise.distanceKm;
    final locationLine = [
      if (distance != null) formatDistanceCompact(distance),
      '${premise.district}, ${premise.state}',
    ].join(' · ');
    return Material(
      key: const ValueKey('nearby-map-info-card'),
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    premise.premiseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    premise.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const ValueKey('nearby-view-store'),
              onPressed: onViewStore,
              child: const Text('View store'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiseList extends StatelessWidget {
  const _PremiseList({
    required this.provider,
    required this.selectedPremiseCode,
    required this.onOpen,
    required this.scrollController,
  });

  final NearbyPremisesProvider provider;
  final int? selectedPremiseCode;
  final ValueChanged<Premise> onOpen;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: provider.load,
    child: ListView.separated(
      key: const ValueKey('nearby-premise-list'),
      controller: scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: provider.premises.length + (provider.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, index) {
        if (index == provider.premises.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: provider.isLoadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      key: const ValueKey('nearby-see-more'),
                      onPressed: provider.loadMore,
                      child: Text(
                        provider.userLocation == null
                            ? 'See more stores'
                            : 'See 5 more stores',
                      ),
                    ),
            ),
          );
        }
        final premise = provider.premises[index];
        return PremiseListTileWidget(
          key: ValueKey('nearby-premise-${premise.premiseCode}'),
          premise: premise,
          selected: premise.premiseCode == selectedPremiseCode,
          onTap: () => onOpen(premise),
        );
      },
    ),
  );
}

class _StoreSummary extends StatelessWidget {
  const _StoreSummary({required this.provider, required this.onUseLocation});

  final NearbyPremisesProvider provider;
  final Future<void> Function() onUseLocation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final location = provider.userLocation;
    final radius = provider.selectedRadiusKm;
    final count = provider.premises.length;
    final distanceCount = provider.premises
        .where((premise) => premise.distanceKm != null)
        .length;

    final String title;
    final String subtitle;
    String storeCount(int value) => value == 1 ? '1 store' : '$value stores';
    if (location != null) {
      title = 'Near your location';
      subtitle = !provider.hasDistanceData
          ? '${storeCount(count)} | store distances unavailable'
          : radius == null
          ? distanceCount == count
                ? '${storeCount(count)} ranked by distance'
                : '$distanceCount of $count store distances found'
          : '${storeCount(count)} within ${radius.round()} km';
    } else if (provider.isBrowsingWithoutLocation) {
      title = 'All stores';
      subtitle = storeCount(count);
    } else {
      title = provider.selectedState ?? 'Near your location';
      subtitle = storeCount(count);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (provider.isBrowsingWithoutLocation)
            TextButton.icon(
              key: const ValueKey('nearby-retry-location'),
              onPressed: onUseLocation,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Use my location'),
            )
          else if (location != null)
            IconButton(
              key: const ValueKey('nearby-refresh-location'),
              tooltip: 'Update current location',
              onPressed: provider.isLocating ? null : onUseLocation,
              icon: provider.isLocating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.provider});
  final NearbyPremisesProvider provider;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      ?provider.selectedState,
      ?provider.selectedDistrict,
      if (provider.selectedRadiusKm case final value?) '${value.round()} km',
    ];
    if (labels.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) => Chip(
          label: Text(labels[index]),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _NearbyFilters {
  const _NearbyFilters({
    required this.radiusKm,
    required this.retailers,
    required this.sortMode,
  });
  final double? radiusKm;
  final Set<String> retailers;
  final NearbySortMode sortMode;
}

class _NearbyFilterSheet extends StatefulWidget {
  const _NearbyFilterSheet({required this.provider});
  final NearbyPremisesProvider provider;

  @override
  State<_NearbyFilterSheet> createState() => _NearbyFilterSheetState();
}

class _NearbyFilterSheetState extends State<_NearbyFilterSheet> {
  static const _anyDistanceSentinel = -1.0;
  double _radiusSentinel = _anyDistanceSentinel;
  final Set<String> _retailers = {};
  NearbySortMode _sortMode = NearbySortMode.nearest;

  @override
  void initState() {
    super.initState();
    _radiusSentinel = widget.provider.selectedRadiusKm ?? _anyDistanceSentinel;
    _retailers.addAll(widget.provider.selectedRetailers);
    _sortMode = widget.provider.sortMode;
  }

  double? get _selectedRadiusKm =>
      _radiusSentinel == _anyDistanceSentinel ? null : _radiusSentinel;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final hasLocation = provider.userLocation != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filter stores',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (hasLocation && provider.hasDistanceData) ...[
            const SizedBox(height: 16),
            Text(
              'Distance',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            RadioGroup<double>(
              groupValue: _radiusSentinel,
              onChanged: (value) => setState(
                () => _radiusSentinel = value ?? _anyDistanceSentinel,
              ),
              child: Column(
                children: [
                  for (final option in NearbyPremisesProvider.radiusOptions)
                    RadioListTile<double>(
                      key: ValueKey('nearby-radius-${option.round()}'),
                      value: option,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text('${option.round()} km'),
                    ),
                  RadioListTile<double>(
                    key: const ValueKey('nearby-radius-any'),
                    value: _anyDistanceSentinel,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: const Text('Any distance'),
                  ),
                ],
              ),
            ),
          ] else if (hasLocation) ...[
            const SizedBox(height: 16),
            const Text(
              'Distance filters will appear when stores have verified map locations.',
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Retailer',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (provider.retailers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Retailer options will appear after stores load.'),
            )
          else
            for (final retailer in provider.retailers)
              CheckboxListTile(
                key: ValueKey('nearby-retailer-$retailer'),
                value: _retailers.contains(retailer),
                dense: true,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(retailer),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _retailers.add(retailer);
                  } else {
                    _retailers.remove(retailer);
                  }
                }),
              ),
          const SizedBox(height: 8),
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          RadioGroup<NearbySortMode>(
            groupValue: _sortMode,
            onChanged: (value) =>
                setState(() => _sortMode = value ?? NearbySortMode.nearest),
            child: const Column(
              children: [
                RadioListTile<NearbySortMode>(
                  key: ValueKey('nearby-sort-nearest'),
                  value: NearbySortMode.nearest,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text('Nearest'),
                ),
                RadioListTile<NearbySortMode>(
                  key: ValueKey('nearby-sort-name'),
                  value: NearbySortMode.name,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text('Store name A–Z'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () => setState(() {
              _radiusSentinel = _anyDistanceSentinel;
              _retailers.clear();
              _sortMode = NearbySortMode.nearest;
            }),
            child: const Text('Reset'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _NearbyFilters(
                radiusKm: _selectedRadiusKm,
                retailers: Set.unmodifiable(_retailers),
                sortMode: _sortMode,
              ),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
