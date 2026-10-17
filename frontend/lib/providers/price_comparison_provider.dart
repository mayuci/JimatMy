import 'package:flutter/foundation.dart';

import '../models/price_comparison.dart';
import '../services/api_service.dart';

class PriceComparisonProvider extends ChangeNotifier {
  PriceComparisonProvider(this._apiService, this.itemCode);

  static const states = ['W.P. Kuala Lumpur', 'Selangor'];
  final ApiService _apiService;
  final int itemCode;
  int _requestVersion = 0;
  List<String> _districts = const [];

  PriceComparison? comparison;
  String? selectedState;
  String? selectedDistrict;
  String? errorMessage;
  bool isLoading = false;

  List<String> get districts => _districts;

  Future<void> load() => _fetch();

  Future<void> selectState(String? state) async {
    selectedState = state;
    selectedDistrict = null;
    _districts = const [];
    await _fetch(refreshDistricts: state != null);
  }

  Future<void> selectDistrict(String? district) async {
    selectedDistrict = district;
    await _fetch();
  }

  Future<void> resetFilters() async {
    selectedState = null;
    selectedDistrict = null;
    _districts = const [];
    await _fetch();
  }

  Future<void> retry() => _fetch(refreshDistricts: selectedState != null);

  Future<void> _fetch({bool refreshDistricts = false}) async {
    final version = ++_requestVersion;
    isLoading = true;
    errorMessage = null;
    comparison = null;
    notifyListeners();
    try {
      final result = await _apiService.getPriceComparison(
        itemCode,
        state: selectedState,
        district: selectedDistrict,
      );
      if (version != _requestVersion) return;
      comparison = result;
      if (refreshDistricts) {
        _districts =
            result.prices.map((price) => price.district).toSet().toList()
              ..sort();
      }
    } on ApiException catch (error) {
      if (version != _requestVersion) return;
      errorMessage = error.message;
    } finally {
      if (version == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }
}
