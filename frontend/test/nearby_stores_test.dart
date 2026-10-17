import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/screens/store_detail_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/services/location_service.dart';
import 'package:jimatmy/services/maps_config_service.dart';
import 'package:jimatmy/widgets/location_status_widget.dart';
import 'package:jimatmy/widgets/premise_map_widget.dart';
import 'package:provider/provider.dart';

const _unmapped = Premise(
  premiseCode: 22063,
  premiseName: 'OFFICIAL TEST PREMISE',
  address: 'NO 1, JALAN TEST',
  postcode: '47301',
  premiseType: 'Pasar Raya / Supermarket',
  district: 'Petaling Jaya',
  state: 'Selangor',
  latitude: null,
  longitude: null,
);

const _mapped = Premise(
  premiseCode: 22063,
  premiseName: 'OFFICIAL TEST PREMISE',
  address: 'NO 1, JALAN TEST',
  postcode: '47301',
  premiseType: 'Pasar Raya / Supermarket',
  district: 'Petaling Jaya',
  state: 'Selangor',
  latitude: 3.1073,
  longitude: 101.6067,
);

const _preciseResolution = ResolvedPremiseLocation(
  resolutionStatus: 'resolved',
  latitude: 3.1073,
  longitude: 101.6067,
  formattedAddress: '1, Jalan Test, 47301 Petaling Jaya, Selangor, Malaysia',
  matchConfidence: 'high',
  partialMatch: false,
  locationType: 'ROOFTOP',
);

const _confirmedNavigation = ResolvedPremiseNavigation(
  confirmed: true,
  placeId: 'ChIJtest-exact-branch',
  displayName: 'OFFICIAL TEST PREMISE',
  formattedAddress: '1, Jalan Test, 47301 Petaling Jaya, Selangor, Malaysia',
  latitude: 3.1073,
  longitude: 101.6067,
);

const _grantedLocation = LocationResult.success(UserLocation(3.1073, 101.6067));
const _deniedLocation = LocationResult.failure(LocationFailure.timeout);

void main() {
  test('premise and resolved models reject unsafe coordinates', () {
    final invalid = ResolvedPremiseLocation.fromJson({
      'resolutionStatus': 'resolved',
      'latitude': double.nan,
      'longitude': 181,
      'formattedAddress': 'Invalid result',
      'matchConfidence': 'high',
      'partialMatch': false,
      'locationType': 'ROOFTOP',
    });
    expect(invalid.coordinates, isNull);
    expect(invalid.isResolved, isFalse);
    expect(invalid.isPreciseMatch, isFalse);
    expect(_mapped.hasCoordinates, isTrue);
  });

  test('precise and approximate match metadata is classified safely', () {
    expect(_preciseResolution.isPreciseMatch, isTrue);
    const approximate = ResolvedPremiseLocation(
      resolutionStatus: 'resolved',
      latitude: 3.1,
      longitude: 101.6,
      formattedAddress: 'Petaling Jaya, Selangor, Malaysia',
      matchConfidence: 'possible',
      partialMatch: true,
      locationType: 'APPROXIMATE',
    );
    expect(approximate.isResolved, isTrue);
    expect(approximate.isPreciseMatch, isFalse);
  });

  test('external search contains the complete official Malaysian address', () {
    final uri = buildOfficialStoreSearchUri(_unmapped);
    final query = uri.queryParameters['query'];
    expect(uri.host, 'www.google.com');
    expect(query, contains(_unmapped.premiseName));
    expect(query, contains(_unmapped.address));
    expect(query, contains('47301'));
    expect(query, contains(_unmapped.district));
    expect(query, contains(_unmapped.state));
    expect(query, endsWith('Malaysia'));
  });

  test('coordinate link uses available API coordinates', () {
    final uri = buildCoordinateStoreUri(_mapped);
    expect(uri.queryParameters['query'], '3.1073,101.6067');

    final fallback = buildCoordinateStoreUri(_unmapped);
    expect(fallback.queryParameters['query'], contains(_unmapped.premiseName));
    expect(fallback.queryParameters['query'], contains(_unmapped.address));
  });

  test('directions URL includes destination_place_id, travel mode and navigate action', () {
    final uri = buildNavigationUri(_confirmedNavigation);
    expect(
      uri.toString(),
      contains('destination_place_id=ChIJtest-exact-branch'),
    );
    expect(uri.toString(), contains('travelmode=driving'));
    expect(uri.toString(), contains('dir_action=navigate'));
    expect(uri.queryParameters['destination'], contains('Jalan Test'));
  });

  test('directions URL omits the origin', () {
    final uri = buildNavigationUri(_confirmedNavigation);
    expect(uri.toString(), isNot(contains('origin=')));
  });

  test('granted location adds origin=lat,lng', () {
    final confirmed = buildNavigationUri(
      _confirmedNavigation,
      origin: const UserLocation(3.1073, 101.6067),
    );
    expect(confirmed.toString(), contains('origin=3.1073,101.6067'));

    final fallback = buildFallbackDirectionsUri(
      _unmapped,
      origin: const UserLocation(3.1073, 101.6067),
    );
    expect(fallback.toString(), contains('origin=3.1073,101.6067'));
  });

  test('denied or missing location omits the origin', () {
    expect(
      buildNavigationUri(_confirmedNavigation).toString(),
      isNot(contains('origin=')),
    );
    expect(
      buildFallbackDirectionsUri(_unmapped).toString(),
      isNot(contains('origin=')),
    );
  });

  test('unconfirmed branch opens directions by address, never a search', () {
    final uri = buildFallbackDirectionsUri(_unmapped);
    expect(uri.path, '/maps/dir/');
    expect(
      uri.queryParameters['destination'],
      contains('OFFICIAL TEST PREMISE'),
    );
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(uri.queryParameters['dir_action'], 'navigate');
    expect(uri.queryParameters.containsKey('destination_place_id'), isFalse);
    expect(uri.toString(), isNot(contains('/maps/search')));
  });

  test('distance formatting remains safe', () {
    expect(formatDistance(0.45), '450 m away');
    expect(formatDistance(12.6), '13 km away');
    expect(formatDistance(null), 'Distance unavailable');
  });

  test('Web map configuration passes a non-empty key to one loader', () async {
    var calls = 0;
    String? receivedKey;
    final config = MapsConfigService(
      webApiKey: 'test-non-secret-key',
      isWeb: true,
      scriptLoader: (key) async {
        calls += 1;
        receivedKey = key;
      },
    );

    expect(await config.prepare(), isNull);
    expect(await config.prepare(), isNull);
    expect(calls, 1);
    expect(receivedKey, 'test-non-secret-key');
  });

  testWidgets('permission failure explains denied-forever state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationStatusWidget(
            failure: LocationFailure.deniedForever,
            onRetry: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('blocked'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('precise result renders map immediately without confirmation', (
    tester,
  ) async {
    final api = _FakePremiseApi(_preciseResolution);
    await tester.pumpWidget(_storeApp(api));
    await _pumpImmediateFutures(tester);

    expect(api.resolveCalls, 1);
    expect(find.byType(PremiseMapWidget), findsOneWidget);
    expect(find.text('Exact location'), findsOneWidget);
    expect(
      find.text('1, Jalan Test, 47301 Petaling Jaya, Selangor, Malaysia'),
      findsOneWidget,
    );
    expect(find.text('Confirm and open map'), findsNothing);
    expect(find.text('Show on map'), findsNothing);
    expect(find.text('Navigate'), findsOneWidget);
  });

  testWidgets('resolution runs only once per Store Detail instance', (
    tester,
  ) async {
    final api = _FakePremiseApi(_preciseResolution);
    await tester.pumpWidget(_storeApp(api));
    await _pumpImmediateFutures(tester);
    await tester.pumpWidget(_storeApp(api));
    await _pumpImmediateFutures(tester);

    expect(api.resolveCalls, 1);
  });

  testWidgets('approximate result shows map with address-based navigation', (
    tester,
  ) async {
    const approximate = ResolvedPremiseLocation(
      resolutionStatus: 'resolved',
      latitude: 3.1,
      longitude: 101.6,
      formattedAddress: 'Petaling Jaya, Selangor, Malaysia',
      matchConfidence: 'possible',
      partialMatch: true,
      locationType: 'APPROXIMATE',
    );
    final api = _FakePremiseApi(approximate);
    await _setNarrowViewport(tester);
    await tester.pumpWidget(_storeApp(api));
    await _pumpImmediateFutures(tester);

    expect(api.resolveCalls, 1);
    expect(find.byType(PremiseMapWidget), findsOneWidget);
    expect(find.byKey(const ValueKey('created-map')), findsOneWidget);
    expect(find.text('Approximate location'), findsOneWidget);
    expect(
      find.textContaining('Petaling Jaya, Selangor, Malaysia'),
      findsOneWidget,
    );
    expect(
      find.text('Based on the official PriceCatcher address'),
      findsOneWidget,
    );
    expect(find.text('Search exact store'), findsOneWidget);
    expect(find.text('Open map'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navigate launch failure shows an error SnackBar', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    messenger.setMockMethodCallHandler(channel, (call) async => false);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final api = _FakePremiseApi(_preciseResolution);
    await tester.pumpWidget(
      _storeApp(api, locationService: _FakeLocationService(_grantedLocation)),
    );
    await _pumpImmediateFutures(tester);

    expect(find.text('Navigate'), findsOneWidget);
    await tester.ensureVisible(find.text('Navigate'));
    await tester.pump();
    await tester.tap(find.text('Navigate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.text('Google Maps navigation could not be opened.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed navigation launches Google Maps externally', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? launchedUrl;
    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    messenger.setMockMethodCallHandler(channel, (call) async {
      launchedUrl = (call.arguments as Map<Object?, Object?>)['url'] as String?;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final api = _FakePremiseApi(_preciseResolution);
    await tester.pumpWidget(
      _storeApp(api, locationService: _FakeLocationService(_grantedLocation)),
    );
    await _pumpImmediateFutures(tester);

    await tester.ensureVisible(find.text('Navigate'));
    await tester.pump();
    await tester.tap(find.text('Navigate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(api.navigationCalls, 1);
    expect(launchedUrl, isNotNull);
    expect(launchedUrl, contains('/maps/dir/?api=1'));
    expect(launchedUrl, isNot(contains('/maps/search')));
    expect(launchedUrl, contains('origin=3.1073,101.6067'));
    expect(launchedUrl, contains('destination_place_id=ChIJtest-exact-branch'));
    expect(launchedUrl, contains('travelmode=driving'));
    expect(launchedUrl, contains('dir_action=navigate'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uncertain navigation result opens address-based directions', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? launchedUrl;
    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    messenger.setMockMethodCallHandler(channel, (call) async {
      launchedUrl = (call.arguments as Map<Object?, Object?>)['url'] as String?;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final api = _FakePremiseApi(
      _preciseResolution,
      navigationResult: const ResolvedPremiseNavigation(confirmed: false),
    );
    await tester.pumpWidget(
      _storeApp(api, locationService: _FakeLocationService(_grantedLocation)),
    );
    await _pumpImmediateFutures(tester);

    await tester.ensureVisible(find.text('Navigate'));
    await tester.pump();
    await tester.tap(find.text('Navigate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    final uri = Uri.parse(launchedUrl!);
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['origin'], '3.1073,101.6067');
    expect(
      uri.queryParameters['destination'],
      contains('OFFICIAL TEST PREMISE'),
    );
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(uri.queryParameters['dir_action'], 'navigate');
    expect(uri.queryParameters.containsKey('destination_place_id'), isFalse);
    expect(launchedUrl, isNot(contains('/maps/search')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied location still opens directions without origin', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? launchedUrl;
    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    messenger.setMockMethodCallHandler(channel, (call) async {
      launchedUrl = (call.arguments as Map<Object?, Object?>)['url'] as String?;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final api = _FakePremiseApi(_preciseResolution);
    await tester.pumpWidget(
      _storeApp(api, locationService: _FakeLocationService(_deniedLocation)),
    );
    await _pumpImmediateFutures(tester);

    await tester.ensureVisible(find.text('Navigate'));
    await tester.pump();
    await tester.tap(find.text('Navigate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(launchedUrl, isNotNull);
    expect(launchedUrl, isNot(contains('origin=')));
    expect(launchedUrl, contains('/maps/dir/?api=1'));
    expect(launchedUrl, contains('destination_place_id=ChIJtest-exact-branch'));
    expect(launchedUrl, contains('travelmode=driving'));
    expect(launchedUrl, contains('dir_action=navigate'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate Navigate taps are deduplicated', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    messenger.setMockMethodCallHandler(channel, (call) async => true);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final locationService = _FakeLocationService(_grantedLocation);
    final gate = Completer<LocationResult>();
    locationService.gate = gate;
    final api = _FakePremiseApi(_preciseResolution);
    await tester.pumpWidget(_storeApp(api, locationService: locationService));
    await _pumpImmediateFutures(tester);

    await tester.ensureVisible(find.text('Navigate'));
    await tester.pump();
    await tester.tap(find.text('Navigate'));
    await tester.tap(find.text('Navigate'));
    gate.complete(_grantedLocation);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(api.navigationCalls, 1);
    expect(locationService.requests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid Malaysian result remains safe with search only', (
    tester,
  ) async {
    const invalid = ResolvedPremiseLocation(
      resolutionStatus: 'resolved',
      latitude: 51.5,
      longitude: -0.1,
      formattedAddress: 'London',
      matchConfidence: 'possible',
      partialMatch: true,
      locationType: 'APPROXIMATE',
    );
    await tester.pumpWidget(_storeApp(_FakePremiseApi(invalid)));
    await _pumpImmediateFutures(tester);

    expect(find.byType(PremiseMapWidget), findsNothing);
    expect(find.text('Search exact store'), findsOneWidget);
    expect(find.text('Navigate'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing Web key shows an actionable map fallback', (
    tester,
  ) async {
    final config = MapsConfigService(webApiKey: '', isWeb: true);
    PremiseMapFailureCategory? failure;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 203,
            child: PremiseMapWidget(
              premises: const [_mapped],
              selectedPremise: _mapped,
              compact: true,
              mapsConfigService: config,
              onOpenExternal: () {},
              onFailure: (value) => failure = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map could not be displayed'), findsOneWidget);
    expect(find.textContaining('Web map key is missing'), findsOneWidget);
    expect(find.text('Retry map'), findsNothing);
    expect(find.text('Search exact store'), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    expect(failure, PremiseMapFailureCategory.missingConfiguration);
  });

  testWidgets('authorization rejection is reported without a retry action', (
    tester,
  ) async {
    final config = MapsConfigService(
      webApiKey: 'test-non-secret-key',
      isWeb: true,
      scriptLoader: (_) => Future<void>.error(Exception('MAPS_AUTH_FAILURE')),
    );
    PremiseMapFailureCategory? failure;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 203,
            child: PremiseMapWidget(
              premises: const [_mapped],
              selectedPremise: _mapped,
              compact: true,
              mapsConfigService: config,
              onOpenExternal: () {},
              onFailure: (value) => failure = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(failure, PremiseMapFailureCategory.authorization);
    expect(find.text('Retry map'), findsNothing);
    expect(find.text('Search exact store'), findsOneWidget);
  });

  testWidgets('map timeout removes the uncreated map panel', (tester) async {
    final config = MapsConfigService(
      webApiKey: 'test-non-secret-key',
      isWeb: true,
      scriptLoader: (_) async {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 203,
            child: PremiseMapWidget(
              premises: const [_mapped],
              selectedPremise: _mapped,
              compact: true,
              mapsConfigService: config,
              mapCreationTimeout: const Duration(milliseconds: 20),
              mapFactory: _uncreatedMap,
              onOpenExternal: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.byKey(const ValueKey('uncreated-map')), findsNothing);
    expect(find.text('Map could not be displayed'), findsOneWidget);
    expect(find.text('Retry map'), findsOneWidget);
    expect(find.text('Search exact store'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Store Detail replaces a failed map with a compact location card',
    (tester) async {
      await _setNarrowViewport(tester);
      final api = _FakePremiseApi(_preciseResolution);
      await tester.pumpWidget(
        _storeApp(
          api,
          mapFactory: _uncreatedMap,
          mapCreationTimeout: const Duration(milliseconds: 20),
        ),
      );
      await _pumpImmediateFutures(tester);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();

      expect(find.byKey(const ValueKey('uncreated-map')), findsNothing);
      expect(find.text('Map could not be displayed'), findsOneWidget);
      expect(find.text(_unmapped.premiseName), findsNWidgets(2));
      expect(find.textContaining(_unmapped.address), findsWidgets);
      expect(find.text('Open in Google Maps'), findsOneWidget);
      expect(find.text('Search exact store'), findsOneWidget);
      expect(find.text('Retry map'), findsOneWidget);
      expect(find.text('Navigate'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _uncreatedMap(
  BuildContext context,
  CameraPosition initialCameraPosition,
  Set<Marker> markers,
  VoidCallback onMapCreated,
) => const ColoredBox(key: ValueKey('uncreated-map'), color: Colors.grey);

Widget _createdMap(
  BuildContext context,
  CameraPosition initialCameraPosition,
  Set<Marker> markers,
  VoidCallback onMapCreated,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) => onMapCreated());
  return const ColoredBox(key: ValueKey('created-map'), color: Colors.green);
}

Widget _storeApp(
  _FakePremiseApi api, {
  PremiseMapFactory mapFactory = _createdMap,
  Duration mapCreationTimeout = const Duration(seconds: 8),
  LocationService? locationService,
}) {
  final config = MapsConfigService(
    webApiKey: 'test-non-secret-key',
    isWeb: true,
    scriptLoader: (_) async {},
  );
  return Provider<ApiService>.value(
    value: api,
    child: MaterialApp(
      home: StoreDetailScreen(
        premise: _unmapped,
        mapsConfigService: config,
        mapFactory: mapFactory,
        mapCreationTimeout: mapCreationTimeout,
        locationService: locationService,
      ),
    ),
  );
}

Future<void> _setNarrowViewport(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpImmediateFutures(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 20));
}

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;
  int requests = 0;
  Completer<LocationResult>? gate;

  @override
  Future<LocationResult> requestCurrentLocation() {
    requests += 1;
    final pending = gate;
    if (pending != null) return pending.future;
    return Future.value(result);
  }
}

class _FakePremiseApi extends ApiService {
  _FakePremiseApi(this.result, {this.navigationResult = _confirmedNavigation});

  final ResolvedPremiseLocation? result;
  final ResolvedPremiseNavigation navigationResult;
  int resolveCalls = 0;
  int navigationCalls = 0;

  @override
  Future<Premise> getPremise(int premiseCode) async => _unmapped;

  @override
  Future<ResolvedPremiseLocation> resolvePremiseLocation(
    int premiseCode,
  ) async {
    resolveCalls += 1;
    final value = result;
    if (value == null) throw StateError('Fake result is not configured');
    return value;
  }

  @override
  Future<ResolvedPremiseNavigation> resolvePremiseNavigation(
    int premiseCode,
  ) async {
    navigationCalls += 1;
    return navigationResult;
  }
}
