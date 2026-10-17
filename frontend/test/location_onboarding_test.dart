import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/providers/app_location_provider.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/services/location_service.dart';
import 'package:jimatmy/widgets/location_onboarding_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch explains location before requesting permission', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final locationService = _FakeLocationService(
      const LocationResult.success(UserLocation(3.1, 101.6)),
    );
    final provider = await _provider(locationService);
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('Find better prices near you'), findsOneWidget);
    expect(find.text('Allow location'), findsOneWidget);
    expect(find.text('Choose location manually'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(locationService.requests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Allow location shows a disabled loading state', (tester) async {
    final completer = Completer<LocationResult>();
    final provider = await _provider(_DelayedLocationService(completer));
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Allow location'));
    await tester.pump();

    expect(find.text('Finding your location…'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Finding your location…'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);

    completer.complete(const LocationResult.success(UserLocation(3.1, 101.6)));
    await tester.pumpAndSettle();
  });

  testWidgets('Allow location stores one-shot coordinates and confirms', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationResult.success(UserLocation(3.1, 101.6)),
    );
    final provider = await _provider(locationService);
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Allow location'));
    await tester.pumpAndSettle();

    expect(locationService.requests, 1);
    expect(provider.userLocation, isNotNull);
    expect(find.text('Find better prices near you'), findsNothing);
    expect(find.text('Location enabled'), findsOneWidget);
  });

  testWidgets('denied permission stays safe and offers manual selection', (
    tester,
  ) async {
    final provider = await _provider(
      _FakeLocationService(
        const LocationResult.failure(LocationFailure.denied),
      ),
    );
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Allow location'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Location permission was denied. You can choose an area manually.',
      ),
      findsOneWidget,
    );
    expect(find.text('Choose location manually'), findsOneWidget);
  });

  testWidgets('Not now persists the first-launch decision', (tester) async {
    final provider = await _provider(
      _FakeLocationService(
        const LocationResult.failure(LocationFailure.unavailable),
      ),
    );
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('jimatmy.location_onboarding_seen'), isTrue);
    expect(find.text('Find better prices near you'), findsNothing);
  });

  testWidgets('manual selection works without requesting device location', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      const LocationResult.failure(LocationFailure.denied),
    );
    final provider = await _provider(locationService);
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose location manually'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your area'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selangor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this area'));
    await tester.pumpAndSettle();

    expect(provider.manualState, 'Selangor');
    expect(provider.userLocation, isNull);
    expect(locationService.requests, 0);
  });

  testWidgets('returning user does not receive the explanation again', (
    tester,
  ) async {
    final provider = await _provider(
      _FakeLocationService(
        const LocationResult.failure(LocationFailure.unavailable),
      ),
      onboardingSeen: true,
    );
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('Home loaded'), findsOneWidget);
    expect(find.text('Find better prices near you'), findsNothing);
  });
}

Future<AppLocationProvider> _provider(
  LocationService locationService, {
  bool onboardingSeen = false,
}) async {
  SharedPreferences.setMockInitialValues({
    if (onboardingSeen) 'jimatmy.location_onboarding_seen': true,
  });
  final preferences = await SharedPreferences.getInstance();
  final provider = AppLocationProvider(
    locationService,
    preferences: preferences,
  );
  await provider.initialize();
  return provider;
}

Widget _app(AppLocationProvider locationProvider) => MultiProvider(
  providers: [
    Provider<ApiService>.value(value: _FakeApi()),
    ChangeNotifierProvider.value(value: locationProvider),
  ],
  child: const MaterialApp(
    home: LocationOnboardingHost(
      child: Scaffold(body: Center(child: Text('Home loaded'))),
    ),
  ),
);

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;
  int requests = 0;

  @override
  Future<LocationResult> requestCurrentLocation() async {
    requests += 1;
    return result;
  }
}

class _DelayedLocationService extends LocationService {
  _DelayedLocationService(this.completer);

  final Completer<LocationResult> completer;

  @override
  Future<LocationResult> requestCurrentLocation() => completer.future;
}

class _FakeApi extends ApiService {
  @override
  Future<List<PremiseFilterGroup>> getPremiseFilters() async => const [
    PremiseFilterGroup(state: 'W.P. Kuala Lumpur', districts: ['Kuala Lumpur']),
    PremiseFilterGroup(state: 'Selangor', districts: ['Petaling Jaya']),
  ];
}
