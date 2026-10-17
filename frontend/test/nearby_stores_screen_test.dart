import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/providers/app_location_provider.dart';
import 'package:jimatmy/screens/nearby_stores_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/services/location_service.dart';
import 'package:jimatmy/services/maps_config_service.dart';
import 'package:jimatmy/widgets/premise_list_tile_widget.dart';
import 'package:jimatmy/widgets/premise_map_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _userLocation = UserLocation(3.1073, 101.6067);

const _mapped = Premise(
  premiseCode: 100,
  premiseName: 'AEON BIG (TEST ONE)',
  address: '1 JALAN TEST',
  postcode: '47301',
  premiseType: 'Supermarket',
  district: 'Petaling Jaya',
  state: 'Selangor',
  latitude: 3.1173,
  longitude: 101.6067,
);

const _secondMapped = Premise(
  premiseCode: 200,
  premiseName: '99 SPEED MART TEST',
  address: '2 JALAN TEST',
  postcode: '47302',
  premiseType: 'Market',
  district: 'Petaling Jaya',
  state: 'Selangor',
  latitude: 3.1573,
  longitude: 101.6067,
);

const _invalid = Premise(
  premiseCode: 300,
  premiseName: "LOTUS'S TEST MARKET",
  address: '3 JALAN TEST',
  postcode: null,
  premiseType: 'Market',
  district: 'Klang',
  state: 'Selangor',
  latitude: 0,
  longitude: 0,
);

List<Premise> _mappedPremises(int count) => List.generate(
  count,
  (index) => Premise(
    premiseCode: 1000 + index,
    premiseName: 'TEST MARKET ${index + 1}',
    address: '${index + 1} JALAN TEST',
    postcode: '50000',
    premiseType: 'Market',
    district: 'Kuala Lumpur',
    state: 'W.P. Kuala Lumpur',
    latitude: _userLocation.latitude + ((count - index) * 0.001),
    longitude: _userLocation.longitude,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first visit shows consent without requesting or loading', (
    tester,
  ) async {
    final harness = await _pumpNearby(tester);

    expect(find.text('Find stores near you'), findsOneWidget);
    expect(
      find.text(
        'Allow location access to show nearby supermarkets and their '
        'distance from you.',
      ),
      findsOneWidget,
    );
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Choose area manually'), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-map-container')), findsNothing);
    expect(harness.location.requests, 0);
    expect(harness.api.premiseCalls, 0);
  });

  testWidgets('permission is requested only after tap and granted opens Map', (
    tester,
  ) async {
    final harness = await _pumpNearby(
      tester,
      locationResult: const LocationResult.success(_userLocation),
    );

    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);

    expect(harness.location.requests, 1);
    expect(harness.api.premiseCalls, 1);
    expect(harness.api.lastCoordinatesOnly, isFalse);
    expect(find.byKey(const ValueKey('nearby-map-container')), findsOneWidget);
    expect(_selectedSegment(tester), NearbyViewMode.map);
    expect(find.text('Near your location'), findsOneWidget);
    expect(find.text('2 stores ranked by distance'), findsOneWidget);
  });

  for (final entry in <(LocationFailure, String)>[
    (LocationFailure.denied, 'Location permission was denied'),
    (LocationFailure.deniedForever, 'Location permission is blocked'),
    (LocationFailure.serviceDisabled, 'Location services are turned off'),
  ]) {
    testWidgets('${entry.$1.name} remains in a safe permission state', (
      tester,
    ) async {
      final harness = await _pumpNearby(
        tester,
        locationResult: LocationResult.failure(entry.$1),
      );

      await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
      await _settle(tester);

      expect(find.textContaining(entry.$2), findsOneWidget);
      expect(find.text('Choose area manually'), findsOneWidget);
      expect(find.text('Browse stores without location'), findsOneWidget);
      expect(harness.location.requests, 1);
      expect(harness.api.premiseCalls, 0);
    });
  }

  testWidgets('denied state allows browsing stores without location', (
    tester,
  ) async {
    final harness = await _pumpNearby(
      tester,
      locationResult: const LocationResult.failure(LocationFailure.denied),
    );

    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('nearby-browse-all')));
    await _settle(tester);

    expect(harness.location.requests, 1);
    expect(harness.api.premiseCalls, 1);
    expect(harness.api.lastCoordinatesOnly, isFalse);
    expect(find.text('All stores'), findsOneWidget);
    expect(find.text('3 stores'), findsOneWidget);
    expect(find.text("LOTUS'S TEST MARKET"), findsOneWidget);
    // No distance is shown without a device location.
    expect(find.text('1.1 km'), findsNothing);
    // Stores without coordinates show a chevron, mapped stores show directions.
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('nearby-trailing-icon-100')))
          .icon,
      Icons.directions_outlined,
    );
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('nearby-trailing-icon-300')))
          .icon,
      Icons.chevron_right_rounded,
    );
  });

  testWidgets('manual area selection never requests device location', (
    tester,
  ) async {
    final harness = await _pumpNearby(tester);

    await tester.tap(find.byKey(const ValueKey('nearby-choose-area')));
    await _settle(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selangor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this area'));
    await _settle(tester);

    expect(harness.location.requests, 0);
    expect(harness.api.premiseCalls, 1);
    expect(_selectedSegment(tester), NearbyViewMode.list);
    expect(find.text('AEON BIG (TEST ONE)'), findsOneWidget);
  });

  testWidgets('local search filters the loaded dataset without new requests', (
    tester,
  ) async {
    final harness = await _grantedHarness(tester);

    await tester.enterText(
      find.byKey(const ValueKey('nearby-search-field')),
      'aeon',
    );
    await tester.pump();

    expect(harness.api.premiseCalls, 1);
    expect(harness.api.lastQuery, '');
    expect(find.text('AEON BIG (TEST ONE)'), findsOneWidget);
    expect(find.text('99 SPEED MART TEST'), findsNothing);
  });

  testWidgets('Map and List switching preserves loaded results and search', (
    tester,
  ) async {
    final harness = await _grantedHarness(tester);
    await tester.enterText(
      find.byKey(const ValueKey('nearby-search-field')),
      'aeon',
    );

    await tester.tap(find.text('List'));
    await tester.pump();
    expect(_selectedSegment(tester), NearbyViewMode.list);
    expect(find.text('AEON BIG (TEST ONE)'), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pump();
    expect(_selectedSegment(tester), NearbyViewMode.map);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('nearby-search-field')))
          .controller
          ?.text,
      'aeon',
    );
    expect(harness.api.premiseCalls, 1);
  });

  testWidgets('location mode loads coordinate stores, markers and distances; '
      'invalid are excluded', (tester) async {
    final harness = await _grantedHarness(tester);
    final markers = harness.map.markers;

    expect(
      markers.map((marker) => marker.markerId.value),
      contains('premise-100'),
    );
    expect(
      markers.map((marker) => marker.markerId.value),
      contains('premise-200'),
    );
    expect(
      markers.map((marker) => marker.markerId.value),
      contains('current-location'),
    );
    expect(
      markers.map((marker) => marker.markerId.value),
      isNot(contains('premise-300')),
    );
    expect(find.text('1.1 km'), findsOneWidget);
    expect(find.text('5.6 km'), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-distance-100')), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-distance-200')), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-distance-300')), findsNothing);
    expect(find.text('Distance unavailable'), findsNothing);
  });

  testWidgets('rows sort nearest first by default', (tester) async {
    final harness = await _grantedHarness(tester);
    await tester.tap(find.text('List'));
    await tester.pump();

    final nearestY = tester
        .getTopLeft(find.byKey(const ValueKey('nearby-premise-100')))
        .dy;
    final fartherY = tester
        .getTopLeft(find.byKey(const ValueKey('nearby-premise-200')))
        .dy;
    expect(nearestY, lessThan(fartherY));
    expect(harness.api.premiseCalls, 1);
  });

  testWidgets('unmapped stores are excluded from distance-ranked results', (
    tester,
  ) async {
    final harness = await _pumpNearby(tester, premiseSource: const [_invalid]);

    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);

    expect(find.text('Nearby distances are not ready'), findsOneWidget);
    expect(find.text("LOTUS'S TEST MARKET"), findsNothing);
    expect(find.text('10 km'), findsNothing);
    expect(harness.location.requests, 1);
  });

  testWidgets('location refresh obtains a fresh fix and reranks stores', (
    tester,
  ) async {
    final harness = await _grantedHarness(tester);

    await tester.tap(find.byKey(const ValueKey('nearby-refresh-location')));
    await _settle(tester);

    expect(harness.location.requests, 2);
    expect(harness.api.premiseCalls, 2);
    expect(find.text('1.1 km'), findsOneWidget);
  });

  testWidgets('nearest endpoint loads 10 stores then five more', (
    tester,
  ) async {
    final source = _mappedPremises(16);
    final harness = await _pumpNearby(tester, premiseSource: source);

    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);
    await tester.tap(find.text('List'));
    await tester.pump();

    expect(harness.api.premiseCalls, 1);
    expect(find.text('10 stores ranked by distance'), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-distance-1015')), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-premise-1005')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('nearby-see-more')),
      260,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('nearby-premise-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('nearby-see-more')));
    await _settle(tester);

    expect(harness.api.premiseCalls, 2);
    expect(find.text('15 stores ranked by distance'), findsOneWidget);
    expect(harness.api.nearbyLimits, [10, 5]);
  });

  testWidgets('marker selection highlights the row and shows the store card', (
    tester,
  ) async {
    final harness = await _grantedHarness(tester);
    final marker = harness.map.markers.singleWhere(
      (value) => value.markerId.value == 'premise-200',
    );

    marker.onTap?.call();
    await tester.pump();

    final row = tester.widget<PremiseListTileWidget>(
      find.byKey(const ValueKey('nearby-premise-200')),
    );
    expect(row.selected, isTrue);
    expect(find.byKey(const ValueKey('nearby-map-info-card')), findsOneWidget);
    expect(find.text('99 SPEED MART TEST'), findsWidgets);
    expect(find.byKey(const ValueKey('nearby-view-store')), findsOneWidget);
  });

  testWidgets('distance and retailer filters stay local and shared', (
    tester,
  ) async {
    final harness = await _grantedHarness(tester);

    // Distance filter keeps only the store within 5 km.
    await tester.tap(find.byKey(const ValueKey('nearby-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nearby-radius-5')));
    await tester.pump();
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await _settle(tester);
    expect(find.text('1 store within 5 km'), findsOneWidget);
    expect(find.text('99 SPEED MART TEST'), findsNothing);

    // Retailer filter narrows the same dataset further.
    await tester.tap(find.byKey(const ValueKey('nearby-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nearby-radius-any')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('nearby-retailer-AEON BIG')),
    );
    await tester.tap(find.byKey(const ValueKey('nearby-retailer-AEON BIG')));
    await tester.pump();
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await _settle(tester);

    expect(find.text('AEON BIG (TEST ONE)'), findsOneWidget);
    expect(find.text('99 SPEED MART TEST'), findsNothing);
    expect(harness.api.premiseCalls, 3);
  });

  testWidgets('sort by store name orders rows A to Z', (tester) async {
    final harness = await _grantedHarness(tester);

    await tester.tap(find.byKey(const ValueKey('nearby-filter-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('nearby-sort-name')));
    await tester.tap(find.byKey(const ValueKey('nearby-sort-name')));
    await tester.pump();
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await _settle(tester);

    final speedMartY = tester
        .getTopLeft(find.byKey(const ValueKey('nearby-premise-200')))
        .dy;
    final aeonY = tester
        .getTopLeft(find.byKey(const ValueKey('nearby-premise-100')))
        .dy;
    expect(speedMartY, lessThan(aeonY));
    expect(harness.api.premiseCalls, 2);
  });

  testWidgets('empty state within radius offers to increase distance', (
    tester,
  ) async {
    final harness = await _grantedHarness(tester);

    await tester.tap(find.byKey(const ValueKey('nearby-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nearby-radius-1')));
    await tester.pump();
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await _settle(tester);

    expect(find.text('No stores found within 1 km.'), findsOneWidget);
    expect(find.text('Increase distance'), findsOneWidget);
    expect(harness.api.premiseCalls, 2);
  });

  testWidgets('browse mode never shows "No mapped stores" under a list', (
    tester,
  ) async {
    final harness = await _pumpNearby(
      tester,
      locationResult: const LocationResult.failure(LocationFailure.denied),
    );
    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('nearby-browse-all')));
    await _settle(tester);
    await tester.tap(find.text('Map'));
    await tester.pump();

    // Keep only the store without coordinates so the map has no markers.
    await tester.tap(find.byKey(const ValueKey('nearby-filter-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey("nearby-retailer-LOTUS'S TEST")),
    );
    await tester.tap(
      find.byKey(const ValueKey("nearby-retailer-LOTUS'S TEST")),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await _settle(tester);

    expect(find.text("LOTUS'S TEST MARKET"), findsOneWidget);
    expect(find.text('No store map locations'), findsOneWidget);
    expect(find.byKey(const ValueKey('nearby-premise-list')), findsOneWidget);
    expect(harness.api.premiseCalls, 1);
  });

  testWidgets('rebuilds do not duplicate premise requests', (tester) async {
    final harness = await _grantedHarness(tester);
    await tester.pump();
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pump();

    expect(harness.api.premiseCalls, 1);
  });

  testWidgets('map creation failure shows a fallback while rows stay usable', (
    tester,
  ) async {
    final harness = await _pumpNearby(
      tester,
      locationResult: const LocationResult.success(_userLocation),
      mapFactory: _neverCreatedMap,
      mapCreationTimeout: const Duration(milliseconds: 300),
    );
    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Map could not be displayed'), findsOneWidget);
    expect(find.text('Retry map'), findsOneWidget);
    expect(find.text('AEON BIG (TEST ONE)'), findsOneWidget);
    expect(harness.api.premiseCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network failure shows a clean retry state', (tester) async {
    final harness = await _pumpNearby(
      tester,
      locationResult: const LocationResult.success(_userLocation),
    );
    harness.api.failPremises = true;
    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);

    expect(find.text('Stores unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consent and browsing layouts fit a narrow viewport', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = await _pumpNearby(
      tester,
      locationResult: const LocationResult.success(_userLocation),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
    await _settle(tester);
    expect(harness.api.premiseCalls, 1);
    expect(find.text('AEON BIG (TEST ONE)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

NearbyViewMode _selectedSegment(WidgetTester tester) => tester
    .widget<SegmentedButton<NearbyViewMode>>(
      find.byType(SegmentedButton<NearbyViewMode>),
    )
    .selected
    .single;

Future<_Harness> _grantedHarness(WidgetTester tester) async {
  final harness = await _pumpNearby(
    tester,
    locationResult: const LocationResult.success(_userLocation),
  );
  await tester.tap(find.byKey(const ValueKey('nearby-use-location')));
  await _settle(tester);
  return harness;
}

Future<_Harness> _pumpNearby(
  WidgetTester tester, {
  LocationResult locationResult = const LocationResult.success(_userLocation),
  PremiseMapFactory? mapFactory,
  Duration mapCreationTimeout = const Duration(seconds: 1),
  List<Premise> premiseSource = const [_mapped, _secondMapped, _invalid],
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final locationService = _FakeLocationService(locationResult);
  final locationProvider = AppLocationProvider(
    locationService,
    preferences: preferences,
  );
  await locationProvider.initialize();
  final api = _FakeNearbyApi(premiseSource);
  final map = _FakeMap();
  final config = MapsConfigService(
    webApiKey: 'test-key',
    isWeb: true,
    scriptLoader: (_) async {},
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AppLocationProvider>.value(
          value: locationProvider,
        ),
      ],
      child: MaterialApp(
        home: NearbyStoresScreen(
          mapsConfigService: config,
          mapFactory: mapFactory ?? map.build,
          mapCreationTimeout: mapCreationTimeout,
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(api, locationService, map);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump(const Duration(milliseconds: 500));
}

Widget _neverCreatedMap(
  BuildContext context,
  CameraPosition initialCameraPosition,
  Set<Marker> markers,
  VoidCallback onMapCreated,
) => const ColoredBox(key: ValueKey('never-created-map'), color: Colors.grey);

class _Harness {
  const _Harness(this.api, this.location, this.map);
  final _FakeNearbyApi api;
  final _FakeLocationService location;
  final _FakeMap map;
}

class _FakeMap {
  Set<Marker> markers = const {};

  Widget build(
    BuildContext context,
    CameraPosition initialCameraPosition,
    Set<Marker> values,
    VoidCallback onMapCreated,
  ) {
    markers = values;
    WidgetsBinding.instance.addPostFrameCallback((_) => onMapCreated());
    return const ColoredBox(
      key: ValueKey('fake-nearby-map'),
      color: Colors.green,
    );
  }
}

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;
  int requests = 0;

  @override
  Future<LocationResult> requestCurrentLocation() async {
    requests += 1;
    return result;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

class _FakeNearbyApi extends ApiService {
  _FakeNearbyApi(this.premiseSource);

  final List<Premise> premiseSource;
  int filterCalls = 0;
  int premiseCalls = 0;
  final List<int> nearbyLimits = [];
  String lastQuery = '';
  String? lastState;
  String? lastDistrict;
  bool lastCoordinatesOnly = false;
  bool failPremises = false;

  @override
  Future<List<PremiseFilterGroup>> getPremiseFilters() async {
    filterCalls += 1;
    return const [
      PremiseFilterGroup(
        state: 'Selangor',
        districts: ['Petaling Jaya', 'Klang'],
      ),
    ];
  }

  @override
  Future<PremisePage> getPremises({
    String query = '',
    String? state,
    String? district,
    bool coordinatesOnly = false,
    required int limit,
    required int offset,
  }) async {
    premiseCalls += 1;
    lastQuery = query;
    lastState = state;
    lastDistrict = district;
    lastCoordinatesOnly = coordinatesOnly;
    if (failPremises) {
      throw const ApiException('Cannot reach the JimatMY server.');
    }
    var source = premiseSource.toList();
    if (coordinatesOnly) {
      source = source.where((premise) => premise.hasCoordinates).toList();
    }
    if (state != null) {
      source = source.where((premise) => premise.state == state).toList();
    }
    if (district != null) {
      source = source.where((premise) => premise.district == district).toList();
    }
    final total = source.length;
    final page = source.skip(offset).take(limit).toList(growable: false);
    return PremisePage(premises: page, total: total);
  }

  @override
  Future<PremisePage> getNearbyPremises({
    required double latitude,
    required double longitude,
    String query = '',
    String? state,
    String? district,
    double? radiusKm,
    required int limit,
    required int offset,
  }) async {
    premiseCalls += 1;
    nearbyLimits.add(limit);
    lastQuery = query;
    lastState = state;
    lastDistrict = district;
    if (failPremises) {
      throw const ApiException('Cannot reach the JimatMY server.');
    }
    final origin = UserLocation(latitude, longitude);
    var source = premiseSource
        .where((premise) => premise.coordinates != null)
        .map((premise) {
          final coordinates = premise.coordinates!;
          return premise.withDistance(
            LocationService().distanceKm(
              origin,
              PremiseCoordinates(coordinates.latitude, coordinates.longitude),
            ),
          );
        })
        .toList();
    if (state != null) {
      source = source.where((premise) => premise.state == state).toList();
    }
    if (district != null) {
      source = source.where((premise) => premise.district == district).toList();
    }
    if (query.trim().isNotEmpty) {
      final needle = query.trim().toLowerCase();
      source = source
          .where(
            (premise) =>
                premise.premiseName.toLowerCase().contains(needle) ||
                premise.address.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (radiusKm != null) {
      source = source
          .where((premise) => premise.distanceKm! <= radiusKm)
          .toList();
    }
    source.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    final total = source.length;
    return PremisePage(
      premises: source.skip(offset).take(limit).toList(growable: false),
      total: total,
    );
  }
}
