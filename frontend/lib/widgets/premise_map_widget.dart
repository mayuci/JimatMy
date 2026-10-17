import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/premise.dart';
import '../services/location_service.dart';
import '../services/maps_config_service.dart';
import 'app_state_widget.dart';

typedef PremiseMapFactory = Widget Function(
  BuildContext context,
  CameraPosition initialCameraPosition,
  Set<Marker> markers,
  VoidCallback onMapCreated,
);

enum PremiseMapStatus { loading, ready, failed }

enum PremiseMapFailureCategory {
  missingConfiguration,
  authorization,
  scriptLoad,
  creationTimeout,
  invalidCoordinates,
}

class PremiseMapWidget extends StatefulWidget {
  const PremiseMapWidget({
    required this.premises,
    this.selectedPremise,
    this.userLocation,
    this.compact = false,
    this.onOpenExternal,
    this.externalActionLabel = 'Search exact store',
    this.onStatusChanged,
    this.onFailure,
    this.onPremiseSelected,
    this.showRecenterButton = false,
    this.centerOnUserLocation = false,
    this.mapsConfigService,
    this.mapCreationTimeout = const Duration(seconds: 8),
    this.mapFactory,
    super.key,
  });

  final List<Premise> premises;
  final Premise? selectedPremise;
  final UserLocation? userLocation;
  final bool compact;
  final VoidCallback? onOpenExternal;
  final String externalActionLabel;
  final ValueChanged<PremiseMapStatus>? onStatusChanged;
  final ValueChanged<PremiseMapFailureCategory>? onFailure;
  final ValueChanged<Premise>? onPremiseSelected;
  final bool showRecenterButton;

  /// When true the initial camera is centred on the user location (when one is
  /// available) instead of the selected premise. Used by the nearby list map;
  /// Store Detail keeps the default store-centred behaviour.
  final bool centerOnUserLocation;
  final MapsConfigService? mapsConfigService;
  final Duration mapCreationTimeout;
  final PremiseMapFactory? mapFactory;

  @override
  State<PremiseMapWidget> createState() => _PremiseMapWidgetState();
}

class _PremiseMapWidgetState extends State<PremiseMapWidget> {
  late final MapsConfigService _mapsConfigService;
  Timer? _creationTimer;
  Timer? _runtimeCheckTimer;
  String? _configurationError;
  String? _mapError;
  bool _preparing = true;
  bool _mapCreated = false;
  int _mapAttempt = 0;
  PremiseMapStatus? _reportedStatus;
  PremiseMapFailureCategory? _failureCategory;
  PremiseMapFailureCategory? _reportedFailure;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _mapsConfigService = widget.mapsConfigService ?? MapsConfigService();
    _prepare();
  }

  @override
  void didUpdateWidget(PremiseMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _mapController;
    final selectedChanged =
        oldWidget.selectedPremise?.premiseCode !=
        widget.selectedPremise?.premiseCode;
    if (selectedChanged && _mapCreated && controller != null) {
      final coordinates = widget.selectedPremise?.coordinates;
      if (coordinates != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(coordinates.latitude, coordinates.longitude),
                14,
              ),
            ),
          );
        });
      }
    }
    final previous = oldWidget.userLocation;
    final current = widget.userLocation;
    final changed =
        previous?.latitude != current?.latitude ||
        previous?.longitude != current?.longitude;
    if (!changed || !_mapCreated || controller == null) return;
    final mapped = widget.premises
        .where((premise) => premise.coordinates != null)
        .toList(growable: false);
    if (mapped.isEmpty) return;
    final selected = _selectedPremise(mapped);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitMarkers(controller, _buildMarkers(mapped, selected));
    });
  }

  Future<void> _prepare() async {
    _creationTimer?.cancel();
    _runtimeCheckTimer?.cancel();
    _reportStatus(PremiseMapStatus.loading);
    if (mounted) {
      setState(() {
        _preparing = true;
        _configurationError = null;
        _mapError = null;
        _mapCreated = false;
        _failureCategory = null;
      });
    }
    final error = await _mapsConfigService.prepare();
    if (!mounted) return;
    setState(() {
      _configurationError = error;
      _preparing = false;
    });
    if (error != null) {
      _reportFailure(_configurationFailureCategory(error));
    }
    if (error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _mapCreated) return;
        _creationTimer = Timer(widget.mapCreationTimeout, () {
          if (!mounted || _mapCreated) return;
          setState(() {
            _mapError = 'The map did not finish opening.';
            _failureCategory = PremiseMapFailureCategory.creationTimeout;
          });
          _reportFailure(PremiseMapFailureCategory.creationTimeout);
        });
      });
    }
  }

  void _handleMapCreated() {
    if (!mounted || _mapCreated) return;
    _creationTimer?.cancel();
    setState(() => _mapCreated = true);
    _reportStatus(PremiseMapStatus.ready);
    var checks = 0;
    _runtimeCheckTimer?.cancel();
    _runtimeCheckTimer = Timer.periodic(const Duration(milliseconds: 250), (
      timer,
    ) {
      checks += 1;
      final error = _mapsConfigService.runtimeError();
      if (error != null && mounted) {
        timer.cancel();
        setState(() {
          _mapError = error;
          _failureCategory = PremiseMapFailureCategory.authorization;
        });
        _reportFailure(PremiseMapFailureCategory.authorization);
      } else if (checks >= 8) {
        timer.cancel();
      }
    });
  }

  void _retryMap() {
    setState(() => _mapAttempt += 1);
    _prepare();
  }

  void _reportStatus(PremiseMapStatus status) {
    if (_reportedStatus == status) return;
    _reportedStatus = status;
    final callback = widget.onStatusChanged;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(status);
    });
  }

  void _reportFailure(PremiseMapFailureCategory category) {
    _reportStatus(PremiseMapStatus.failed);
    if (_reportedFailure == category) return;
    _reportedFailure = category;
    if (kDebugMode) {
      debugPrint('JimatMY map failure category: ${category.name}');
    }
    final callback = widget.onFailure;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(category);
    });
  }

  PremiseMapFailureCategory _configurationFailureCategory(String error) {
    final normalized = error.toLowerCase();
    if (normalized.contains('key is missing') ||
        normalized.contains('not configured')) {
      return PremiseMapFailureCategory.missingConfiguration;
    }
    if (normalized.contains('authorized')) {
      return PremiseMapFailureCategory.authorization;
    }
    return PremiseMapFailureCategory.scriptLoad;
  }

  @override
  void dispose() {
    _creationTimer?.cancel();
    _runtimeCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapped = widget.premises
        .where((premise) => premise.coordinates != null)
        .toList(growable: false);
    if (mapped.isEmpty) {
      _reportFailure(PremiseMapFailureCategory.invalidCoordinates);
      final hasPremises = widget.premises.isNotEmpty;
      return AppStateWidget(
        icon: Icons.location_off_outlined,
        title: hasPremises ? 'Map could not be displayed' : 'No mapped stores',
        message: hasPremises
            ? 'This store location is not valid.'
            : 'No store locations are available to display.',
        compact: true,
      );
    }
    if (_preparing) {
      return const _MapSkeleton();
    }
    final failure = _configurationError ?? _mapError;
    if (failure != null) {
      return _MapFallback(
        diagnostic: failure,
        onRetry: _failureCategory == PremiseMapFailureCategory.creationTimeout
            ? _retryMap
            : null,
        onOpenExternal: widget.onOpenExternal,
        externalActionLabel: widget.externalActionLabel,
      );
    }

    final selected = _selectedPremise(mapped);
    final selectedCoordinates = selected.coordinates;
    if (selectedCoordinates == null) {
      _reportFailure(PremiseMapFailureCategory.invalidCoordinates);
      return _MapFallback(
        diagnostic: 'This store location is not valid.',
        onRetry: null,
        onOpenExternal: widget.onOpenExternal,
        externalActionLabel: widget.externalActionLabel,
      );
    }
    final markers = _buildMarkers(mapped, selected);
    final location = widget.userLocation;
    final initialTarget =
        widget.centerOnUserLocation &&
            location != null &&
            _isValidLocation(location)
        ? LatLng(location.latitude, location.longitude)
        : LatLng(selectedCoordinates.latitude, selectedCoordinates.longitude);
    final position = CameraPosition(
      target: initialTarget,
      zoom: widget.compact ? 14 : 11,
    );
    final factory = widget.mapFactory ?? _defaultMapFactory;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.compact ? 12 : 0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          KeyedSubtree(
            key: ValueKey('premise-map-$_mapAttempt'),
            child: factory(context, position, markers, _handleMapCreated),
          ),
          if (widget.showRecenterButton)
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 2,
                shape: const CircleBorder(),
                child: IconButton(
                  key: const ValueKey('nearby-map-recenter'),
                  tooltip: 'Recenter map',
                  onPressed: _mapCreated ? _recenter : null,
                  icon: const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Premise _selectedPremise(List<Premise> mapped) {
    final requested = widget.selectedPremise;
    if (requested != null && requested.coordinates != null) return requested;
    return mapped.first;
  }

  Set<Marker> _buildMarkers(List<Premise> mapped, Premise selected) {
    final markers = mapped
        .map((premise) {
          final coordinates = premise.coordinates;
          if (coordinates == null) return null;
          return Marker(
            markerId: MarkerId('premise-${premise.premiseCode}'),
            position: LatLng(coordinates.latitude, coordinates.longitude),
            infoWindow: InfoWindow(
              title: premise.premiseName,
              snippet: premise.distanceKm == null
                  ? premise.district
                  : '${formatDistanceCompact(premise.distanceKm!)} · ${premise.district}',
            ),
            onTap: () => widget.onPremiseSelected?.call(premise),
            icon: premise.premiseCode == selected.premiseCode
                ? BitmapDescriptor.defaultMarker
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
          );
        })
        .whereType<Marker>()
        .toSet();
    final location = widget.userLocation;
    if (location != null && _isValidLocation(location)) {
      markers.add(
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: const InfoWindow(title: 'Your location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    return markers;
  }

  bool _isValidLocation(UserLocation location) {
    return location.latitude.isFinite &&
        location.longitude.isFinite &&
        location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180 &&
        (location.latitude != 0 || location.longitude != 0);
  }

  Future<void> _recenter() async {
    final controller = _mapController;
    if (controller == null) return;
    final location = widget.userLocation;
    if (location != null && _isValidLocation(location)) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          14,
        ),
      );
      return;
    }
    final coordinates = widget.selectedPremise?.coordinates;
    if (coordinates == null) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(coordinates.latitude, coordinates.longitude),
        14,
      ),
    );
  }

  Widget _defaultMapFactory(
    BuildContext context,
    CameraPosition initialCameraPosition,
    Set<Marker> markers,
    VoidCallback onMapCreated,
  ) {
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: !widget.compact,
      onMapCreated: (controller) {
        _mapController = controller;
        onMapCreated();
        _fitMarkers(controller, markers);
      },
    );
  }

  Future<void> _fitMarkers(
    GoogleMapController controller,
    Set<Marker> markers,
  ) async {
    if (markers.length < 2) return;
    final positions = markers.map((marker) => marker.position).toList();
    final south = positions
        .map((position) => position.latitude)
        .reduce((a, b) => a < b ? a : b);
    final north = positions
        .map((position) => position.latitude)
        .reduce((a, b) => a > b ? a : b);
    final west = positions
        .map((position) => position.longitude)
        .reduce((a, b) => a < b ? a : b);
    final east = positions
        .map((position) => position.longitude)
        .reduce((a, b) => a > b ? a : b);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      if (south == north && west == east) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(positions.first, 14),
        );
      } else {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(south, west),
              northeast: LatLng(north, east),
            ),
            52,
          ),
        );
      }
    } catch (_) {
      // The map can be disposed while its delayed camera update is pending.
    }
  }
}

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({
    required this.diagnostic,
    required this.onRetry,
    required this.onOpenExternal,
    required this.externalActionLabel,
  });

  final String diagnostic;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenExternal;
  final String externalActionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: colors.primary, size: 20),
            const SizedBox(height: 2),
            Text(
              'Map could not be displayed',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Search for this store directly in Google Maps. $diagnostic',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onRetry != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                    ),
                    icon: const Icon(Icons.refresh, size: 17),
                    label: const Text('Retry map'),
                  ),
                if (onOpenExternal != null)
                  FilledButton.icon(
                    onPressed: onOpenExternal,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 17),
                    label: Text(externalActionLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
