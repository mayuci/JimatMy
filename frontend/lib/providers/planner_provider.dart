import 'package:flutter/foundation.dart';

import '../models/planner_models.dart';
import '../services/api_service.dart';

class PlannerProvider extends ChangeNotifier {
  PlannerProvider(this._apiService);

  final ApiService _apiService;
  PlannerOverview? overview;
  List<BasketTemplate> templates = const [];
  String? errorMessage;
  bool isLoading = false;
  bool isSaving = false;
  bool isLoadingTemplates = false;
  bool hasLoadedTemplates = false;
  VoidCallback? onListCountChanged;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      overview = await _apiService.getPlannerOverview();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTemplates() async {
    if (isLoadingTemplates || hasLoadedTemplates) return;
    isLoadingTemplates = true;
    notifyListeners();
    try {
      templates = await _apiService.getBasketTemplates();
      hasLoadedTemplates = true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoadingTemplates = false;
      notifyListeners();
    }
  }

  Future<String?> createList(String name) async {
    final validName = name.trim();
    if (validName.isEmpty || validName.length > 100) {
      return 'Name must be between 1 and 100 characters.';
    }
    final error = await _mutate(
      () => _apiService.createShoppingList(validName),
    );
    if (error == null) onListCountChanged?.call();
    return error;
  }

  Future<ShoppingListDetail?> createFromTemplate(String templateKey) async {
    ShoppingListDetail? created;
    final error = await _mutate(() async {
      created = await _apiService.createBasketFromTemplate(templateKey);
      return created;
    });
    if (error == null) onListCountChanged?.call();
    if (error != null) errorMessage = error;
    return created;
  }

  Future<String?> renameList(String listId, String name) async {
    final validName = name.trim();
    if (validName.isEmpty || validName.length > 100) {
      return 'Name must be between 1 and 100 characters.';
    }
    return _mutate(() => _apiService.renameShoppingList(listId, validName));
  }

  Future<String?> deleteList(String listId) async {
    final error = await _mutate(() => _apiService.deleteShoppingList(listId));
    if (error == null) onListCountChanged?.call();
    return error;
  }

  Future<String?> setBudget(double amount) async {
    if (!amount.isFinite || amount <= 0) {
      return 'Enter a positive budget amount.';
    }
    final month = overview?.month ?? _currentMonth();
    return _mutate(() => _apiService.setBudget(month, amount));
  }

  Future<String?> _mutate(Future<Object?> Function() operation) async {
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

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void clear() {
    overview = null;
    templates = const [];
    errorMessage = null;
    isLoading = false;
    isSaving = false;
    isLoadingTemplates = false;
    hasLoadedTemplates = false;
    notifyListeners();
  }
}
