import 'package:flutter/foundation.dart';

import '../models/planner_models.dart';
import '../services/api_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  ShoppingListProvider(this._apiService, this.listId);

  final ApiService _apiService;
  final String listId;
  ShoppingListDetail? list;
  String? errorMessage;
  String? errorCode;
  bool isLoading = false;
  bool isSaving = false;

  static String? validateQuantity(double quantity) =>
      quantity.isFinite && quantity >= 1
      ? null
      : 'Quantity must be at least 1.';

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    errorCode = null;
    notifyListeners();
    try {
      list = await _apiService.getShoppingList(listId);
    } on ApiException catch (error) {
      errorMessage = error.message;
      errorCode = error.code;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addItem(int itemCode, double quantity) {
    final validation = validateQuantity(quantity);
    if (validation != null) return Future.value(validation);
    return _mutate(
      () => _apiService.addShoppingListItem(listId, itemCode, quantity),
    );
  }

  Future<String?> updateQuantity(ShoppingListItem item, double quantity) {
    final validation = validateQuantity(quantity);
    if (validation != null) return Future.value(validation);
    return _mutate(
      () => _apiService.updateShoppingListItem(
        listId,
        item.listItemId,
        quantity: quantity,
      ),
    );
  }

  Future<String?> setCompleted(ShoppingListItem item, bool value) => _mutate(
    () => _apiService.updateShoppingListItem(
      listId,
      item.listItemId,
      isChecked: value,
    ),
  );

  Future<String?> removeItem(ShoppingListItem item) => _mutate(
    () => _apiService.deleteShoppingListItem(listId, item.listItemId),
  );

  Future<String?> _mutate(Future<void> Function() operation) async {
    if (isSaving) return 'Please wait for the current update to finish.';
    isSaving = true;
    notifyListeners();
    try {
      await operation();
      await load();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
