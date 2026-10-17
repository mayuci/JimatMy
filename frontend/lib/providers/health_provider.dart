import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

enum HealthStatus { checking, connected, failed }

class HealthProvider extends ChangeNotifier {
  HealthProvider(this._apiService);
  final ApiService _apiService;
  HealthStatus status = HealthStatus.checking;
  String? errorMessage;

  Future<bool> check() async {
    status = HealthStatus.checking;
    errorMessage = null;
    notifyListeners();
    try {
      await _apiService.checkHealth();
      status = HealthStatus.connected;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      status = HealthStatus.failed;
      errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }
}
