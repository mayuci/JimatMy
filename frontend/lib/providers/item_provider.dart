import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../services/api_service.dart';

class ItemProvider extends ChangeNotifier {
  ItemProvider(this._apiService);
  static const pageSize = 30;
  final ApiService _apiService;
  final List<Item> _items = [];
  Timer? _debounce;
  int _requestVersion = 0;
  int _total = 0;
  bool _initialized = false;

  List<Item> get items => List.unmodifiable(_items);
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  String query = '';
  String? category;
  String? state;
  String? district;
  bool hasAvailablePrices = true;
  int get total => _total;
  bool get hasMore => _items.length < _total;

  void selectCategory(String? value) {
    if (category == value) {
      if (value != null) category = null;
    } else {
      category = value;
    }
    _load(reset: true);
  }

  void setFilters({
    String query = '',
    String? category,
    String? state,
    String? district,
    bool hasAvailablePrices = true,
  }) {
    _debounce?.cancel();
    this.query = query.trim();
    this.category = category;
    this.state = state;
    this.district = district;
    this.hasAvailablePrices = hasAvailablePrices;
    _initialized = true;
    _load(reset: true);
  }

  Future<void> loadInitial() async {
    if (_initialized) return;
    _initialized = true;
    await _load(reset: true);
  }

  void search(String value) {
    query = value;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _load(reset: true),
    );
  }

  void clearSearch() {
    _debounce?.cancel();
    query = '';
    _load(reset: true);
  }

  void applyFilters({
    required String? category,
    required String? state,
    required String? district,
    required bool hasAvailablePrices,
  }) {
    _debounce?.cancel();
    this.category = category;
    this.state = state;
    this.district = district;
    this.hasAvailablePrices = hasAvailablePrices;
    _load(reset: true);
  }

  Future<void> retry() => _load(reset: true);

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    final version = ++_requestVersion;
    if (reset) {
      isLoading = true;
      errorMessage = null;
    } else {
      isLoadingMore = true;
    }
    notifyListeners();
    try {
      final page = await _apiService.getItems(
        query: query,
        category: category,
        state: state,
        district: district,
        limit: pageSize,
        offset: reset ? 0 : _items.length,
        pricedOnly: hasAvailablePrices,
      );
      if (version != _requestVersion) return;
      if (reset) _items.clear();
      final existingCodes = _items.map((item) => item.itemCode).toSet();
      _items.addAll(
        page.items.where((item) => existingCodes.add(item.itemCode)),
      );
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
