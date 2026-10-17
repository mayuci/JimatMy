import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/premise.dart';
import '../providers/app_location_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/maps_config_service.dart';
import '../widgets/app_state_widget.dart';
import '../widgets/location_status_widget.dart';
import '../widgets/premise_map_widget.dart';
import 'premise_map_screen.dart';

String buildOfficialStoreAddress(Premise premise) => <String>[
  premise.premiseName,
  premise.address,
  ?premise.postcode,
  premise.district,
  premise.state,
  'Malaysia',
].map((value) => value.trim()).where((value) => value.isNotEmpty).join(', ');

Uri buildOfficialStoreSearchUri(Premise premise) {
  final query = buildOfficialStoreAddress(premise);
  return Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
  );
}

String _originQuery(UserLocation? origin) =>
    origin == null ? '' : '&origin=${origin.latitude},${origin.longitude}';

/// Builds the Google Maps driving-directions URL for a confirmed Place ID.
/// The user's position is included as the origin when available; otherwise it
/// is omitted so Google Maps can use its own current-location handling.
Uri buildNavigationUri(
  ResolvedPremiseNavigation navigation, {
  UserLocation? origin,
}) {
  final destination =
      navigation.formattedAddress ?? navigation.displayName ?? '';
  return Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '${_originQuery(origin)}'
    '&destination=${Uri.encodeComponent(destination)}'
    '&destination_place_id=${Uri.encodeComponent(navigation.placeId ?? '')}'
    '&travelmode=driving'
    '&dir_action=navigate',
  );
}

/// Builds the Google Maps driving-directions URL for an unconfirmed branch
/// using the official store name and full address as the destination. This
/// always stays on the directions flow and never falls back to a store search.
Uri buildFallbackDirectionsUri(Premise premise, {UserLocation? origin}) {
  return Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '${_originQuery(origin)}'
    '&destination=${Uri.encodeComponent(buildOfficialStoreAddress(premise))}'
    '&travelmode=driving'
    '&dir_action=navigate',
  );
}

Uri buildCoordinateStoreUri(Premise premise) {
  final coordinates = premise.coordinates;
  if (coordinates == null) return buildOfficialStoreSearchUri(premise);
  final query = Uri.encodeComponent(
    '${coordinates.latitude},${coordinates.longitude}',
  );
  return Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
}

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({
    required this.premise,
    this.userLocation,
    this.locationService,
    this.mapsConfigService,
    this.mapFactory,
    this.mapCreationTimeout = const Duration(seconds: 8),
    super.key,
  }) : premiseCode = null;

  const StoreDetailScreen.fromPremiseCode({
    required int premiseCode,
    this.userLocation,
    this.locationService,
    this.mapsConfigService,
    this.mapFactory,
    this.mapCreationTimeout = const Duration(seconds: 8),
    super.key,
  }) : premiseCode = premiseCode,
       premise = null,
       assert(premiseCode > 0);

  final int? premiseCode;
  final Premise? premise;
  int? get requestedPremiseCode => premiseCode ?? premise?.premiseCode;
  final UserLocation? userLocation;
  final LocationService? locationService;
  final MapsConfigService? mapsConfigService;
  final PremiseMapFactory? mapFactory;
  final Duration mapCreationTimeout;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  Premise? _premise;
  ResolvedPremiseLocation? _resolution;
  UserLocation? _userLocation;
  LocationFailure? _locationFailure;
  String? _loadError;
  String? _resolutionError;
  bool _resolutionAttempted = false;
  bool _resolving = false;
  bool _locating = false;
  PremiseMapStatus _mapStatus = PremiseMapStatus.loading;
  PremiseMapFailureCategory? _mapFailure;
  int _mapAttempt = 0;
  ResolvedPremiseNavigation? _navigationResult;
  bool _navigating = false;

  LocationService get _locationService =>
      widget.locationService ?? LocationService();

  @override
  void initState() {
    super.initState();
    _premise = widget.premise;
    _userLocation = widget.userLocation;
    _loadOfficialPremise();
  }

  Future<void> _loadOfficialPremise() async {
    if (mounted) setState(() => _loadError = null);
    final premiseCode = widget.requestedPremiseCode;
    if (premiseCode == null || premiseCode <= 0) {
      if (mounted) {
        setState(() => _loadError = 'Store details are unavailable.');
      }
      return;
    }
    try {
      final official = await context.read<ApiService>().getPremise(premiseCode);
      if (!mounted) return;
      final display = _withRememberedLocation(official);
      setState(() => _premise = display);
      if (!display.hasCoordinates) {
        unawaited(_resolveLocationOnce(display));
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    }
  }

  Premise _withRememberedLocation(Premise official) {
    if (official.hasCoordinates) return official;
    final remembered = _premise?.coordinates;
    if (remembered == null) return official;
    return Premise(
      premiseCode: official.premiseCode,
      premiseName: official.premiseName,
      address: official.address,
      postcode: official.postcode,
      premiseType: official.premiseType,
      district: official.district,
      state: official.state,
      latitude: remembered.latitude,
      longitude: remembered.longitude,
      distanceKm: official.distanceKm,
    );
  }

  Future<void> _resolveLocationOnce(Premise premise) async {
    if (_resolutionAttempted || _resolving) return;
    _resolutionAttempted = true;
    setState(() {
      _resolving = true;
      _resolutionError = null;
    });
    try {
      final result = await context.read<ApiService>().resolvePremiseLocation(
        premise.premiseCode,
      );
      if (!mounted) return;
      setState(() {
        _resolution = result;
        _mapStatus = PremiseMapStatus.loading;
        if (!result.isResolved) {
          _resolutionError = 'This store address could not be matched.';
        }
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _resolutionError = error.message);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _requestUserLocation() async {
    setState(() {
      _locating = true;
      _locationFailure = null;
    });
    final shared = Provider.of<AppLocationProvider?>(context, listen: false);
    final result = shared == null
        ? await _locationService.requestCurrentLocation()
        : await shared.requestCurrentLocation();
    if (!mounted) return;
    setState(() {
      _userLocation = result.location;
      _locationFailure = result.failure;
      _locating = false;
    });
  }

  Premise _displayPremise(Premise premise, UserLocation? userLocation) {
    var mapped = premise;
    final resolution = _resolution;
    if (!mapped.hasCoordinates && resolution != null && resolution.isResolved) {
      mapped = premise.withResolvedLocation(resolution);
    }
    final coordinates = mapped.coordinates;
    if (coordinates != null && userLocation != null) {
      mapped = mapped.withDistance(
        _locationService.distanceKm(
          userLocation,
          PremiseCoordinates(coordinates.latitude, coordinates.longitude),
        ),
      );
    }
    return mapped;
  }

  Future<void> _navigate(Premise premise) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    final api = context.read<ApiService>();
    try {
      // Foreground location: denied or timed-out still opens directions.
      final locationResult = await _locationService.requestCurrentLocation();
      final origin = locationResult.location;

      var navigation = _navigationResult;
      if (navigation == null) {
        navigation = await api.resolvePremiseNavigation(premise.premiseCode);
        _navigationResult = navigation;
      }
      if (!mounted) return;

      final placeId = navigation.placeId;
      final confirmed =
          navigation.confirmed && placeId != null && placeId.isNotEmpty;
      final uri = confirmed
          ? buildNavigationUri(navigation, origin: origin)
          : buildFallbackDirectionsUri(premise, origin: origin);
      await _launch(uri, 'Google Maps navigation could not be opened.');
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _openInGoogleMaps(Premise premise) => _launch(
    buildOfficialStoreSearchUri(premise),
    'Google Maps could not be opened.',
  );

  Future<void> _openCoordinateInGoogleMaps(Premise premise) => _launch(
    buildCoordinateStoreUri(premise),
    'Google Maps could not be opened.',
  );

  Future<void> _launch(Uri uri, String failureMessage) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  void _openMap(Premise premise, UserLocation? userLocation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PremiseMapScreen(
          premises: [premise],
          selectedPremise: premise,
          userLocation: userLocation,
        ),
      ),
    );
  }

  void _handleMapStatus(PremiseMapStatus status) {
    if (status == PremiseMapStatus.failed) return;
    if (!mounted || _mapStatus == status) return;
    setState(() {
      _mapStatus = status;
      if (status == PremiseMapStatus.ready) _mapFailure = null;
    });
  }

  void _handleMapFailure(PremiseMapFailureCategory failure) {
    if (!mounted) return;
    setState(() {
      _mapStatus = PremiseMapStatus.failed;
      _mapFailure = failure;
    });
  }

  void _retryMap() {
    setState(() {
      _mapStatus = PremiseMapStatus.loading;
      _mapFailure = null;
      _mapAttempt += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final premise = _premise;
    final sharedLocation = Provider.of<AppLocationProvider?>(context)
        ?.userLocation;
    final userLocation = sharedLocation ?? _userLocation;
    return Scaffold(
      appBar: AppBar(title: const Text('Store details')),
      body: _loadError != null && premise == null
          ? AppStateWidget(
              icon: Icons.wifi_off_outlined,
              title: 'Store unavailable',
              message: _loadError ?? 'The store could not be loaded.',
              actionLabel: 'Retry',
              onAction: _loadOfficialPremise,
            )
          : premise == null
          ? const Center(child: CircularProgressIndicator())
          : _buildDetails(premise, userLocation),
    );
  }

  Widget _buildDetails(Premise premise, UserLocation? userLocation) {
    final mapped = _displayPremise(premise, userLocation);
    final resolution = _resolution;
    final hasLocation = mapped.hasCoordinates;
    final precise =
        hasLocation &&
        (premise.hasCoordinates || resolution?.isPreciseMatch == true);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StoreHeaderCard(premise: premise),
                const SizedBox(height: 14),
                if (_resolving)
                  const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _LocationSkeleton(),
                  )
                else if (hasLocation) ...[
                  if (_mapStatus == PremiseMapStatus.failed)
                    _MapFailureCard(
                      premise: premise,
                      onOpen: () => _openCoordinateInGoogleMaps(mapped),
                      onSearchExact: () => _openInGoogleMaps(premise),
                      onRetry:
                          _mapFailure ==
                              PremiseMapFailureCategory.creationTimeout
                          ? _retryMap
                          : null,
                    )
                  else ...[
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: PremiseMapWidget(
                        key: ValueKey('store-map-$_mapAttempt'),
                        premises: [mapped],
                        selectedPremise: mapped,
                        userLocation: userLocation,
                        compact: true,
                        onOpenExternal: () => _openInGoogleMaps(premise),
                        externalActionLabel: 'Search exact store',
                        onStatusChanged: _handleMapStatus,
                        onFailure: _handleMapFailure,
                        mapsConfigService: widget.mapsConfigService,
                        mapFactory: widget.mapFactory,
                        mapCreationTimeout: widget.mapCreationTimeout,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _AccuracyBadge(precise: precise),
                    const SizedBox(height: 7),
                    Text(
                      resolution?.formattedAddress ?? premise.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!precise) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Based on the official PriceCatcher address',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                  if (_mapStatus == PremiseMapStatus.ready &&
                      mapped.distanceKm != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      precise
                          ? _formatMapDistance(mapped.distanceKm)
                          : 'Approx. ${_formatMapDistance(mapped.distanceKm)}',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                  if (_mapStatus == PremiseMapStatus.ready) ...[
                    const SizedBox(height: 12),
                    if (userLocation == null)
                      OutlinedButton.icon(
                        onPressed: _locating ? null : _requestUserLocation,
                        icon: _locating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Use my location'),
                      ),
                    if (_locationFailure case final failure?)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: LocationStatusWidget(
                          failure: failure,
                          onRetry: _requestUserLocation,
                          onOpenSettings: Provider.of<AppLocationProvider?>(
                            context,
                            listen: false,
                          )?.openAppSettings,
                          onOpenLocationSettings:
                              Provider.of<AppLocationProvider?>(
                                context,
                                listen: false,
                              )?.openLocationSettings,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!precise)
                          FilledButton.icon(
                            onPressed: () => _openInGoogleMaps(premise),
                            icon: const Icon(Icons.search),
                            label: const Text('Search exact store'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _openMap(mapped, userLocation),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open map'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _navigating
                            ? null
                            : () => _navigate(premise),
                        icon: _navigating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.navigation_outlined),
                        label: const Text('Navigate'),
                      ),
                    ),
                  ],
                ] else
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _NoLocationFallback(
                      message:
                          _resolutionError ??
                          'A map location was not available for this store.',
                      onSearch: () => _openInGoogleMaps(premise),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatMapDistance(double? distanceKm) => distanceKm == null
    ? 'Distance unavailable'
    : '${distanceKm.toStringAsFixed(1)} km away';

class _StoreHeaderCard extends StatelessWidget {
  const _StoreHeaderCard({required this.premise});

  final Premise premise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    premise.premiseName,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(premise.premiseType),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      premise.address,
                      ?premise.postcode,
                      premise.district,
                      premise.state,
                    ].where((value) => value.trim().isNotEmpty).join(', '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE59A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  'PriceCatcher official data',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSkeleton extends StatelessWidget {
  const _LocationSkeleton();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Finding this store…'),
      ],
    ),
  );
}

class _AccuracyBadge extends StatelessWidget {
  const _AccuracyBadge({required this.precise});

  final bool precise;

  @override
  Widget build(BuildContext context) {
    final background = precise
        ? const Color(0xFFDDF4E6)
        : const Color(0xFFFFE59A);
    final foreground = precise
        ? const Color(0xFF0D5B3D)
        : const Color(0xFF5F4700);
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            precise ? 'Exact location' : 'Approximate location',
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoLocationFallback extends StatelessWidget {
  const _NoLocationFallback({required this.message, required this.onSearch});

  final String message;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_searching,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Text('Search exact store'),
          ),
        ],
      ),
    ),
  );
}

class _MapFailureCard extends StatelessWidget {
  const _MapFailureCard({
    required this.premise,
    required this.onOpen,
    required this.onSearchExact,
    this.onRetry,
  });

  final Premise premise;
  final VoidCallback onOpen;
  final VoidCallback onSearchExact;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final address = <String>[
      premise.address,
      ?premise.postcode,
      premise.district,
      premise.state,
      'Malaysia',
    ].where((value) => value.trim().isNotEmpty).join(', ');
    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Map could not be displayed',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        premise.premiseName,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in Google Maps'),
                ),
                OutlinedButton.icon(
                  onPressed: onSearchExact,
                  icon: const Icon(Icons.search),
                  label: const Text('Search exact store'),
                ),
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry map'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
