import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../models/user_features.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._apiService);

  final ApiService _apiService;
  ProfileSummary? summary;
  List<FavoriteItem> favorites = const [];
  List<SearchHistoryEntry> history = const [];
  bool isLoading = false;
  String? errorMessage;
  int _requestVersion = 0;
  Future<void>? _loadOperation;

  Future<void> load({bool force = false}) {
    if (!force && _loadOperation != null) return _loadOperation!;
    final operation = _load(++_requestVersion);
    _loadOperation = operation;
    return operation.whenComplete(() {
      if (identical(_loadOperation, operation)) _loadOperation = null;
    });
  }

  Future<void> _load(int version) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final summaryValue = await _apiService.getProfileSummary();
      if (version != _requestVersion) return;
      summary = summaryValue;
      notifyListeners();
      final favoriteRequest = _capture(
        _apiService.getFavoriteItems,
        'Your favourites could not be loaded.',
      );
      final historyRequest = _capture(
        _apiService.getSearchHistory,
        'Your recent views could not be loaded.',
      );
      final favoriteResult = await favoriteRequest;
      final historyResult = await historyRequest;
      if (version != _requestVersion) return;
      if (favoriteResult.data != null) favorites = favoriteResult.data!;
      if (historyResult.data != null) history = historyResult.data!;
      errorMessage = [
        favoriteResult.error,
        historyResult.error,
      ].whereType<String>().join(' ');
      if (errorMessage!.isEmpty) errorMessage = null;
    } on ApiException catch (error) {
      if (version == _requestVersion) errorMessage = error.message;
    } catch (_) {
      if (version == _requestVersion) {
        errorMessage = 'Your profile information could not be loaded.';
      }
    } finally {
      if (version == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<({T? data, String? error})> _capture<T>(
    Future<T> Function() request,
    String fallbackMessage,
  ) async {
    try {
      return (data: await request(), error: null);
    } on ApiException catch (error) {
      return (data: null, error: error.message);
    } catch (_) {
      return (data: null, error: fallbackMessage);
    }
  }

  Future<void> refreshSummary() async {
    try {
      summary = await _apiService.getProfileSummary();
      notifyListeners();
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
    }
  }

  bool isFavorite(int itemCode) =>
      favorites.any((item) => item.itemCode == itemCode);

  Future<bool> loadFavoriteStatus(int itemCode) =>
      _apiService.getFavoriteStatus(itemCode);

  Future<String?> setFavorite(
    Item item,
    bool desired, {
    bool? knownCurrent,
  }) async {
    final oldFavorites = favorites;
    final oldSummary = summary;
    final existed = knownCurrent ?? isFavorite(item.itemCode);
    if (existed == desired) return null;

    if (desired) {
      favorites = [
        FavoriteItem(
          itemCode: item.itemCode,
          itemName: item.itemName,
          unit: item.unit,
          itemGroup: item.itemGroup,
          itemCategory: item.itemCategory,
          favoritedAt: DateTime.now(),
          lowestPrice: item.latestPrices.isEmpty
              ? null
              : item.latestPrices
                    .map((price) => price.price)
                    .reduce((a, b) => a < b ? a : b),
          premiseCount: item.latestPrices.length,
        ),
        ...favorites,
      ];
    } else {
      favorites = favorites
          .where((favorite) => favorite.itemCode != item.itemCode)
          .toList(growable: false);
    }
    final currentCount = oldSummary?.favoriteItemCount;
    final adjustedCount = currentCount == null
        ? favorites.length
        : currentCount + (desired ? 1 : -1);
    _updateSummary(favoriteCount: adjustedCount < 0 ? 0 : adjustedCount);
    notifyListeners();
    try {
      if (desired) {
        await _apiService.addFavoriteItem(item.itemCode);
      } else {
        await _apiService.removeFavoriteItem(item.itemCode);
      }
      return null;
    } on ApiException catch (error) {
      favorites = oldFavorites;
      summary = oldSummary;
      notifyListeners();
      return error.message;
    }
  }

  Future<String?> removeFavorite(int itemCode) async {
    FavoriteItem? item;
    for (final favorite in favorites) {
      if (favorite.itemCode == itemCode) item = favorite;
    }
    if (item == null) return null;
    return setFavorite(item, false);
  }

  Future<void> recordView(Item item) async {
    final oldHistory = history;
    final oldSummary = summary;
    final existed = history.any((entry) => entry.itemCode == item.itemCode);
    final optimistic = SearchHistoryEntry(
      historyId: 'pending-${item.itemCode}',
      itemCode: item.itemCode,
      itemName: item.itemName,
      unit: item.unit,
      itemGroup: item.itemGroup,
      itemCategory: item.itemCategory,
      lastViewedAt: DateTime.now(),
      wasCreated: !existed,
    );
    history = [
      optimistic,
      ...history.where((entry) => entry.itemCode != item.itemCode),
    ].take(50).toList(growable: false);
    _updateSummary(historyCount: history.length);
    notifyListeners();
    try {
      final saved = await _apiService.recordItemView(item.itemCode);
      history = [
        saved,
        ...history.where((entry) => entry.itemCode != item.itemCode),
      ].take(50).toList(growable: false);
      _updateSummary(historyCount: history.length);
      notifyListeners();
    } on ApiException {
      history = oldHistory;
      summary = oldSummary;
      notifyListeners();
    }
  }

  Future<String?> clearHistory() async {
    final oldHistory = history;
    final oldSummary = summary;
    history = const [];
    _updateSummary(historyCount: 0);
    notifyListeners();
    try {
      await _apiService.clearSearchHistory();
      return null;
    } on ApiException catch (error) {
      history = oldHistory;
      summary = oldSummary;
      notifyListeners();
      return error.message;
    }
  }

  void _updateSummary({int? favoriteCount, int? historyCount}) {
    final current = summary;
    if (current == null) return;
    summary = ProfileSummary(
      favoriteItemCount: favoriteCount ?? current.favoriteItemCount,
      historyCount: historyCount ?? current.historyCount,
      shoppingListCount: current.shoppingListCount,
    );
  }

  void clear() {
    _requestVersion++;
    summary = null;
    favorites = const [];
    history = const [];
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }
}
