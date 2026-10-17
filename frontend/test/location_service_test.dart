import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jimatmy/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGeolocatorPlatform geolocator;

  setUp(() {
    geolocator = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = geolocator;
  });

  LocationService service({bool? isWeb}) => LocationService(isWeb: isWeb);

  test('reports service disabled without requesting a fix', () async {
    geolocator.serviceEnabled = false;
    final result = await service().requestCurrentLocation();
    expect(result.failure, LocationFailure.serviceDisabled);
    expect(result.location, isNull);
    expect(geolocator.currentCalls, 0);
    expect(geolocator.lastKnownCalls, 0);
  });

  test('denied permission is reported without requesting a fix', () async {
    geolocator.permission = LocationPermission.denied;
    final result = await service().requestCurrentLocation();
    expect(result.failure, LocationFailure.denied);
    expect(geolocator.currentCalls, 0);
  });

  test('denied forever is reported for the app-settings action', () async {
    geolocator.permission = LocationPermission.deniedForever;
    final result = await service().requestCurrentLocation();
    expect(result.failure, LocationFailure.deniedForever);
    expect(geolocator.currentCalls, 0);
  });

  test('permission is requested once when initially denied', () async {
    geolocator.permission = LocationPermission.denied;
    geolocator.onPermissionRequest = () async => LocationPermission.whileInUse;
    final result = await service().requestCurrentLocation();
    expect(geolocator.permissionRequests, 1);
    expect(result.location, isNotNull);
  });

  test('while-in-use permission proceeds to a location fix', () async {
    geolocator.permission = LocationPermission.whileInUse;
    final result = await service().requestCurrentLocation();
    expect(result.location, isNotNull);
    expect(geolocator.currentCalls, 1);
  });

  test('a fresh fix always replaces an available cached position', () async {
    geolocator.cachedPosition = _position(3.1, 101.6);
    geolocator.onCurrentPosition = () async => _position(4.5, 102.0);
    final result = await service().requestCurrentLocation();
    expect(result.location?.latitude, 4.5);
    expect(result.location?.longitude, 102.0);
    expect(geolocator.lastKnownCalls, 1);
    expect(geolocator.currentCalls, 1);
  });

  test(
    'cached position is used as a fallback when the fresh fix fails',
    () async {
      geolocator.cachedPosition = _position(3.1, 101.6);
      geolocator.onCurrentPosition = () async =>
          throw TimeoutException('location timeout');
      final result = await service().requestCurrentLocation();
      expect(result.failure, isNull);
      expect(result.location?.latitude, 3.1);
      expect(result.location?.longitude, 101.6);
      expect(geolocator.currentCalls, 1);
    },
  );

  test('falls back to current position when no cache exists', () async {
    final result = await service().requestCurrentLocation();
    expect(result.location?.latitude, 3.1);
    expect(result.location?.longitude, 101.6);
    expect(geolocator.lastKnownCalls, 1);
    expect(geolocator.currentCalls, 1);
  });

  test('invalid coordinates are rejected', () async {
    geolocator.onCurrentPosition = () async => _position(double.nan, 101.6);
    final result = await service().requestCurrentLocation();
    expect(result.failure, LocationFailure.unavailable);
    expect(result.location, isNull);
  });

  test('timeout maps to the retry failure', () async {
    geolocator.onCurrentPosition = () async =>
        throw TimeoutException('location timeout');
    final result = await service().requestCurrentLocation();
    expect(result.failure, LocationFailure.timeout);
  });

  test('concurrent requests share a single platform request', () async {
    final gate = Completer<void>();
    geolocator.onCurrentPosition = () =>
        gate.future.then((_) => _position(3.1, 101.6));
    final shared = service();
    final first = shared.requestCurrentLocation();
    final second = shared.requestCurrentLocation();
    gate.complete();
    final a = await first;
    final b = await second;
    expect(geolocator.currentCalls, 1);
    expect(a.location, isNotNull);
    expect(b.location, isNotNull);
  });

  test('web skips the cached-position platform call', () async {
    geolocator.cachedPosition = _position(3.1, 101.6);
    final result = await service(isWeb: true).requestCurrentLocation();
    expect(geolocator.lastKnownCalls, 0);
    expect(geolocator.currentCalls, 1);
    expect(result.location, isNotNull);
  });

  test('web keeps low accuracy and Android uses high accuracy', () async {
    await service(isWeb: true).requestCurrentLocation();
    expect(geolocator.lastSettings?.accuracy, LocationAccuracy.low);
    await service(isWeb: false).requestCurrentLocation();
    expect(geolocator.lastSettings?.accuracy, LocationAccuracy.high);
  });
}

Position _position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position? cachedPosition;
  Future<Position> Function()? onCurrentPosition;
  Future<LocationPermission> Function()? onPermissionRequest;
  LocationSettings? lastSettings;
  int currentCalls = 0;
  int lastKnownCalls = 0;
  int permissionRequests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests += 1;
    final request = onPermissionRequest;
    if (request != null) permission = await request();
    return permission;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    lastKnownCalls += 1;
    return cachedPosition;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    currentCalls += 1;
    lastSettings = locationSettings;
    final current = onCurrentPosition;
    if (current != null) return current();
    return _position(3.1, 101.6);
  }
}
