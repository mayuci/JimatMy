import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationFailure {
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
  timeout,
}

class UserLocation {
  const UserLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class LocationResult {
  const LocationResult.success(this.location) : failure = null;
  const LocationResult.failure(this.failure) : location = null;
  final UserLocation? location;
  final LocationFailure? failure;
}

class LocationService {
  LocationService({bool? isWeb}) : _isWeb = isWeb ?? kIsWeb;

  final bool _isWeb;
  Future<LocationResult>? _inFlightRequest;

  /// Returns the in-flight request when one is already running so rapid taps
  /// cannot start parallel platform location requests.
  Future<LocationResult> requestCurrentLocation() {
    final inFlight = _inFlightRequest;
    if (inFlight != null) return inFlight;
    final request = _requestCurrentLocation();
    _inFlightRequest = request;
    request.whenComplete(() {
      if (identical(_inFlightRequest, request)) _inFlightRequest = null;
    });
    return request;
  }

  Future<LocationResult> _requestCurrentLocation() async {
    try {
      _log('checking location services');
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      }

      _log('checking location permission');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _log('requesting location permission');
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationFailure.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(LocationFailure.deniedForever);
      }
      // whileInUse (and always) are granted, so continue.

      // Quick initial fallback only: the cached position is never returned as
      // the final answer when a fresh fix can be obtained.
      UserLocation? cached;
      if (!_isWeb) {
        _log('requesting cached position');
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          cached = _validatedLocation(
            lastKnown?.latitude,
            lastKnown?.longitude,
          );
        } catch (_) {
          _log('cached position unavailable');
        }
      }

      // Always request a fresh fix afterward. A null cache, a cache failure,
      // or a timed-out cache lookup does not stop this request.
      Position? fresh;
      LocationFailure? freshFailure;
      try {
        _log('requesting current position');
        fresh = await Geolocator.getCurrentPosition(
          locationSettings: _currentLocationSettings(),
        );
      } on LocationServiceDisabledException {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      } on PermissionDeniedException {
        return const LocationResult.failure(LocationFailure.denied);
      } on TimeoutException {
        freshFailure = LocationFailure.timeout;
      } on UnsupportedError {
        freshFailure = LocationFailure.unavailable;
      } catch (_) {
        freshFailure = LocationFailure.unavailable;
      }

      final freshLocation = _validatedLocation(
        fresh?.latitude,
        fresh?.longitude,
      );
      if (freshLocation != null) {
        return LocationResult.success(freshLocation);
      }
      if (cached != null) {
        _log('falling back to cached position');
        return LocationResult.success(cached);
      }
      return LocationResult.failure(
        freshFailure ?? LocationFailure.unavailable,
      );
    } on LocationServiceDisabledException {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const LocationResult.failure(LocationFailure.denied);
    } on TimeoutException {
      return const LocationResult.failure(LocationFailure.timeout);
    } on UnsupportedError {
      return const LocationResult.failure(LocationFailure.unavailable);
    } catch (_) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }

  /// Android uses high accuracy with a bounded wait so the emulator or device
  /// returns a precise fix quickly. Web keeps its previous browser settings so
  /// web behaviour is unchanged.
  LocationSettings _currentLocationSettings() {
    if (_isWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 12),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    );
  }

  UserLocation? _validatedLocation(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    if (!latitude.isFinite || !longitude.isFinite) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;
    return UserLocation(latitude, longitude);
  }

  /// Debug-only stage logging. Coordinates are intentionally never logged.
  void _log(String stage) {
    if (kDebugMode) {
      debugPrint('[LocationService] $stage');
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  double distanceKm(UserLocation origin, PremiseCoordinates destination) =>
      Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      ) /
      1000;
}

class PremiseCoordinates {
  const PremiseCoordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}
