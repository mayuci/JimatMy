import 'package:flutter/foundation.dart';

import '../models/best_places_models.dart';
import '../services/api_service.dart';

class BestPlacesProvider extends ChangeNotifier {
  BestPlacesProvider(
    this._apiService,
    this.listId, {
    BestPlacesFilters initialFilters = const BestPlacesFilters(),
  }) : filters = initialFilters;

  final ApiService _apiService;
  final String listId;
  int _requestVersion = 0;

  BestPlacesResponse? response;
  BestPlacesFilters filters;
  final List<BasketStore> stores = [];
  String? errorMessage;
  String? errorCode;
  bool isLoading = false;
  bool isLoadingMore = false;

  Future<void> load() => _fetch(page: 1, append: false);

  Future<void> refresh() => _fetch(page: 1, append: false);

  Future<void> applyFilters(BestPlacesFilters value) async {
    filters = value;
    response = null;
    stores.clear();
    await _fetch(page: 1, append: false);
  }

  Future<void> resetFilters() => applyFilters(const BestPlacesFilters());

  Future<void> useLocation(
    double latitude,
    double longitude, {
    int radiusKm = 10,
  }) => applyFilters(
    BestPlacesFilters(
      coverage: filters.coverage,
      sort: filters.sort,
      state: filters.state,
      district: filters.district,
      maxTotal: filters.maxTotal,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    ),
  );

  Future<void> setRadius(int radiusKm) {
    if (!filters.hasLocation) return Future<void>.value();
    return useLocation(
      filters.latitude!,
      filters.longitude!,
      radiusKm: radiusKm,
    );
  }

  Future<void> loadNextPage() async {
    final data = response;
    if (isLoading || isLoadingMore || data == null || !data.hasNextPage) return;
    await _fetch(page: data.pagination.page + 1, append: true);
  }

  Future<void> _fetch({required int page, required bool append}) async {
    if (append && isLoadingMore) return;
    final version = ++_requestVersion;
    if (append) {
      isLoadingMore = true;
    } else {
      isLoading = true;
    }
    errorMessage = null;
    errorCode = null;
    notifyListeners();

    try {
      final next = await _apiService.getBestPlaces(
        listId,
        filters: filters,
        page: page,
      );
      if (version != _requestVersion) return;
      response = next;
      if (!append) stores.clear();
      final existing = stores.map((store) => store.premiseCode).toSet();
      stores.addAll(
        next.stores.where((store) => existing.add(store.premiseCode)),
      );
    } on ApiException catch (error) {
      if (version != _requestVersion) return;
      errorMessage = error.message;
      errorCode = error.code;
    } finally {
      if (version == _requestVersion) {
        isLoading = false;
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
