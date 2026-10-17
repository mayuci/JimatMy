import 'package:flutter/foundation.dart';

import '../models/premise.dart';
import 'app_location_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

enum NearbySortMode { nearest, name }

class NearbyPremisesProvider extends ChangeNotifier {
  NearbyPremisesProvider(this._apiService, this._appLocation) {
    selectedState = _appLocation.manualState;
    selectedDistrict = _appLocation.manualDistrict;
  }

  static const pageSize = 30;
  static const initialNearbyCount = 10;
  static const nearbyLoadMoreCount = 5;
  static const defaultRadiusKm = 10.0;
  static const radiusOptions = <double>[1, 3, 5, 10, 20];

  final ApiService _apiService;
  final AppLocationProvider _appLocation;
  final List<Premise> _premises = [];
  int _total = 0;
  int _requestVersion = 0;
  Future<void>? _loadFuture;
  bool _browsingWithoutLocation = false;

  List<PremiseFilterGroup> filters = const [];
  String query = '';
  String? selectedState;
  String? selectedDistrict;
  double? selectedRadiusKm;
  Set<String> selectedRetailers = {};
  NearbySortMode sortMode = NearbySortMode.nearest;
  String? errorMessage;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasLoaded = false;

  UserLocation? get userLocation => _appLocation.userLocation;
  LocationFailure? get locationFailure => _appLocation.failure;
  bool get isLocating => _appLocation.isRequesting;
  bool get hasAnyPremises => _premises.isNotEmpty;
  bool get hasDistanceData =>
      _premises.any((premise) => premise.distanceKm != null);
  bool get isBrowsingWithoutLocation => _browsingWithoutLocation;

  /// The filtered, sorted store list shared by the List and Map views. All
  /// filtering (search, radius, retailer) and sorting run locally against the
  /// cached premise pool, so no network request happens per keystroke.
  List<Premise> get premises {
    final radius = selectedRadiusKm;
    final location = userLocation;
    final canApplyRadius = location != null && hasDistanceData;
    final retailers = selectedRetailers;
    final search = query.trim().toLowerCase();
    final result = _premises.where((premise) {
      if (radius != null && canApplyRadius) {
        final distance = premise.distanceKm;
        if (distance == null || distance > radius) return false;
      }
      if (retailers.isNotEmpty && !retailers.contains(premise.retailer)) {
        return false;
      }
      if (search.isNotEmpty) {
        final haystack =
            '${premise.premiseName} ${premise.address} '
                    '${premise.district} ${premise.state}'
                .toLowerCase();
        if (!haystack.contains(search)) return false;
      }
      return true;
    }).toList();
    result.sort((first, second) {
      if (sortMode == NearbySortMode.name) {
        return first.premiseName.toLowerCase().compareTo(
          second.premiseName.toLowerCase(),
        );
      }
      final firstDistance = first.distanceKm;
      final secondDistance = second.distanceKm;
      if (firstDistance == null) return secondDistance == null ? 0 : 1;
      if (secondDistance == null) return -1;
      return firstDistance.compareTo(secondDistance);
    });
    return List.unmodifiable(result);
  }

  List<Premise> get mappedPremises =>
      premises.where((premise) => premise.hasCoordinates).toList();

  List<String> get states => filters.map((group) => group.state).toList();
  List<String> get districts => selectedState == null
      ? const []
      : filters
            .where((group) => group.state == selectedState)
            .expand((group) => group.districts)
            .toList();

  /// Distinct retailer brands derived from the loaded premise pool, sorted
  /// alphabetically for the filter sheet.
  List<String> get retailers {
    final values =
        _premises
            .map((premise) => premise.retailer.trim())
            .where((retailer) => retailer.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  bool get hasMore => _premises.length < _total;

  Future<void> load() {
    final active = _loadFuture;
    if (active != null) return active;
    final request = _load();
    _loadFuture = request;
    request.whenComplete(() {
      if (identical(_loadFuture, request)) _loadFuture = null;
    });
    return request;
  }

  Future<void> _load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      filters = await _apiService.getPremiseFilters();
      if (!states.contains(selectedState)) {
        selectedState = null;
        selectedDistrict = null;
      } else if (!districts.contains(selectedDistrict)) {
        selectedDistrict = null;
      }
      await _fetch(reset: true, notifyLoading: false);
      hasLoaded = true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Local search: narrows the already loaded pool without a new network call.
  void search(String value) {
    query = value;
    notifyListeners();
  }

  /// Browsing fallback used when device location is unavailable or denied.
  /// Loads the full premise pool (no coordinate requirement, no distances)
  /// so search/list browsing still works without location access.
  Future<void> browseAllStores() async {
    _browsingWithoutLocation = true;
    selectedRadiusKm = null;
    selectedState = null;
    selectedDistrict = null;
    if (hasLoaded) {
      await _fetch(reset: true);
    } else {
      await load();
    }
  }

  Future<LocationResult> useMyLocation() async {
    _browsingWithoutLocation = false;
    final result = await _appLocation.requestCurrentLocation();
    if (result.location != null) {
      selectedRadiusKm = null;
      selectedState = null;
      selectedDistrict = null;
      if (hasLoaded) {
        await _fetch(reset: true);
      }
    }
    return result;
  }

  Future<void> useManualArea() async {
    _browsingWithoutLocation = false;
    selectedState = _appLocation.manualState;
    selectedDistrict = _appLocation.manualDistrict;
    selectedRadiusKm = null;
    if (hasLoaded) {
      await _fetch(reset: true);
    } else {
      await load();
    }
  }

  Future<void> applyFilters({
    required double? radiusKm,
    required Set<String> retailers,
    required NearbySortMode sortMode,
  }) async {
    selectedRadiusKm = userLocation == null ? null : radiusKm;
    selectedRetailers = retailers;
    this.sortMode = sortMode;
    if (userLocation != null) {
      await _fetch(reset: true);
    } else {
      notifyListeners();
    }
  }

  Future<void> resetFilters() async {
    selectedRadiusKm = null;
    selectedRetailers = {};
    sortMode = NearbySortMode.nearest;
    if (userLocation != null) {
      await _fetch(reset: true);
    } else {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) return;
    await _fetch(reset: false);
  }

  Future<void> _fetch({required bool reset, bool notifyLoading = true}) async {
    final version = ++_requestVersion;
    if (reset) {
      isLoading = notifyLoading;
      errorMessage = null;
    } else {
      isLoadingMore = true;
    }
    notifyListeners();
    try {
      final locationMode = userLocation != null && !_browsingWithoutLocation;
      final requestLimit = locationMode
          ? (reset ? initialNearbyCount : nearbyLoadMoreCount)
          : pageSize;
      final requestedOffset = reset ? 0 : _premises.length;
      final location = userLocation;
      final page = locationMode && location != null
          ? await _apiService.getNearbyPremises(
              latitude: location.latitude,
              longitude: location.longitude,
              state: selectedState,
              district: selectedDistrict,
              radiusKm: selectedRadiusKm,
              limit: requestLimit,
              offset: requestedOffset,
            )
          : await _apiService.getPremises(
              query: '',
              state: selectedState,
              district: selectedDistrict,
              coordinatesOnly: false,
              limit: requestLimit,
              offset: requestedOffset,
            );
      if (version != _requestVersion) return;
      if (reset) _premises.clear();
      final existingCodes = _premises
          .map((premise) => premise.premiseCode)
          .toSet();
      final additions = page.premises
          .where((premise) => existingCodes.add(premise.premiseCode))
          .toList(growable: false);
      _premises.addAll(additions);
      _total = page.total;
      errorMessage = null;
    } on ApiException catch (error) {
      if (version != _requestVersion) return;
      errorMessage = error.message;
    } finally {
      if (version == _requestVersion) {
        isLoading = false;
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
