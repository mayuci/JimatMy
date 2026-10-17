import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_service.dart';

class AppLocationProvider extends ChangeNotifier {
  AppLocationProvider(this._locationService, {SharedPreferences? preferences}) {
    _preferences = preferences;
  }

  static const _onboardingSeenKey = 'jimatmy.location_onboarding_seen';
  static const _manualStateKey = 'jimatmy.manual_location_state';
  static const _manualDistrictKey = 'jimatmy.manual_location_district';

  final LocationService _locationService;
  SharedPreferences? _preferences;

  bool isInitialized = false;
  bool onboardingSeen = false;
  bool isRequesting = false;
  UserLocation? userLocation;
  LocationFailure? failure;
  String? manualState;
  String? manualDistrict;

  bool get shouldShowOnboarding => isInitialized && !onboardingSeen;
  bool get hasDeviceLocation => userLocation != null;
  String get locationLabel {
    if (hasDeviceLocation) return 'Current location';
    if (manualDistrict != null) return manualDistrict!;
    if (manualState != null) return manualState!;
    return 'Location not selected';
  }

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    onboardingSeen = _preferences?.getBool(_onboardingSeenKey) ?? false;
    manualState = _preferences?.getString(_manualStateKey);
    manualDistrict = _preferences?.getString(_manualDistrictKey);
    isInitialized = true;
    notifyListeners();
  }

  Future<LocationResult> requestCurrentLocation() async {
    await markOnboardingSeen();
    isRequesting = true;
    failure = null;
    notifyListeners();
    final result = await _locationService.requestCurrentLocation();
    userLocation = result.location;
    failure = result.failure;
    if (result.location != null) {
      manualState = null;
      manualDistrict = null;
      await _preferences?.remove(_manualStateKey);
      await _preferences?.remove(_manualDistrictKey);
    }
    isRequesting = false;
    notifyListeners();
    return result;
  }

  Future<void> chooseManualArea(String state, String? district) async {
    await markOnboardingSeen();
    userLocation = null;
    failure = null;
    manualState = state.trim();
    manualDistrict = district?.trim().isEmpty == true ? null : district?.trim();
    await _preferences?.setString(_manualStateKey, manualState!);
    if (manualDistrict == null) {
      await _preferences?.remove(_manualDistrictKey);
    } else {
      await _preferences?.setString(_manualDistrictKey, manualDistrict!);
    }
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    if (onboardingSeen) return;
    onboardingSeen = true;
    await _preferences?.setBool(_onboardingSeenKey, true);
    notifyListeners();
  }

  Future<bool> openAppSettings() => _locationService.openAppSettings();

  Future<bool> openLocationSettings() =>
      _locationService.openLocationSettings();
}
