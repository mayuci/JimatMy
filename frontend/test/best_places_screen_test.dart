import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/best_places_models.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/providers/best_places_provider.dart';
import 'package:jimatmy/providers/app_location_provider.dart';
import 'package:jimatmy/screens/best_places_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/services/location_service.dart';
import 'package:provider/provider.dart';

BasketStoreItem _item(int code, String name, double price) => BasketStoreItem(
  itemCode: code,
  itemName: name,
  unit: '1 unit',
  requestedQuantity: 1,
  unitPrice: price,
  lineTotal: price,
  priceDate: '2026-07-31',
);

BasketStore _complete(
  int code,
  String name,
  double total, {
  double? distanceKm,
}) => BasketStore(
  premiseCode: code,
  premiseName: name,
  premiseType: 'HYPERMARKET',
  address: 'Official address',
  district: 'Petaling',
  state: 'Selangor',
  coveredItemCount: 2,
  totalItemCount: 2,
  isComplete: true,
  basketTotal: total,
  partialTotal: null,
  latestPriceDate: '2026-07-31',
  items: [
    _item(1, '100 PLUS (ORIGINAL)', 2.9),
    _item(2, 'AYAM BERSIH - STANDARD', total - 2.9),
  ],
  missingItems: const [],
  distanceKm: distanceKm,
);

BasketStore _incomplete(int code) => BasketStore(
  premiseCode: code,
  premiseName: 'ECONSAVE KLANG',
  premiseType: 'SUPERMARKET',
  address: 'Other official address',
  district: 'Klang',
  state: 'Selangor',
  coveredItemCount: 1,
  totalItemCount: 2,
  isComplete: false,
  basketTotal: null,
  partialTotal: 2.9,
  latestPriceDate: '2026-07-30',
  items: [_item(1, '100 PLUS (ORIGINAL)', 2.9)],
  missingItems: const [
    MissingBasketItem(
      itemCode: 2,
      itemName: 'AYAM BERSIH - STANDARD',
      requestedQuantity: 1,
    ),
  ],
);

BestPlacesResponse _response({
  List<BasketStore>? stores,
  int page = 1,
  int totalPages = 1,
  int? totalResults,
}) {
  final values =
      stores ??
      [
        _complete(10, 'AEON BIG', 10.85),
        _complete(12, "LOTUS'S", 11.2),
        _incomplete(11),
      ];
  return BestPlacesResponse(
    listId: 'list-1',
    listName: 'Weekly groceries',
    itemCount: 2,
    requestedItems: const [
      RequestedBasketItem(
        itemCode: 1,
        itemName: '100 PLUS (ORIGINAL)',
        unit: '1 unit',
        requestedQuantity: 1,
      ),
      RequestedBasketItem(
        itemCode: 2,
        itemName: 'AYAM BERSIH - STANDARD',
        unit: '1 unit',
        requestedQuantity: 1,
      ),
    ],
    summary: const BestPlacesSummary(
      totalPremises: 3,
      completePremises: 2,
      incompletePremises: 1,
      lowestCompleteTotal: 10.85,
      highestCompleteTotal: 11.2,
    ),
    stores: values,
    twoStoreCombination: null,
    pagination: BestPlacesPagination(
      page: page,
      limit: 20,
      totalResults: totalResults ?? values.length,
      totalPages: totalPages,
    ),
    filterOptions: const BestPlacesFilterOptions(
      states: ['Selangor'],
      districts: [
        DistrictOption(state: 'Selangor', district: 'Klang'),
        DistrictOption(state: 'Selangor', district: 'Petaling'),
      ],
    ),
  );
}

class _FakeBestPlacesApi extends ApiService {
  _FakeBestPlacesApi(this.responses);
  final List<BestPlacesResponse> responses;
  final List<BestPlacesFilters> filtersSeen = [];
  final List<int> pagesSeen = [];
  int calls = 0;

  @override
  Future<BestPlacesResponse> getBestPlaces(
    String listId, {
    BestPlacesFilters filters = const BestPlacesFilters(),
    int page = 1,
    int limit = 20,
  }) async {
    filtersSeen.add(filters);
    pagesSeen.add(page);
    final index = calls < responses.length ? calls : responses.length - 1;
    calls += 1;
    return responses[index];
  }

  @override
  Future<Premise> getPremise(int premiseCode) async => Premise(
    premiseCode: premiseCode,
    premiseName: 'STORE $premiseCode',
    address: 'Official address',
    postcode: '47500',
    premiseType: 'HYPERMARKET',
    district: 'Petaling',
    state: 'Selangor',
    latitude: 3.1,
    longitude: 101.6,
  );
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
    super.didPush(route, previousRoute);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeBestPlacesApi api, {
  Size size = const Size(390, 844),
  NavigatorObserver? observer,
  UserLocation? location,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final locationProvider = AppLocationProvider(LocationService())
    ..userLocation = location;
  await tester.pumpWidget(
    ChangeNotifierProvider<AppLocationProvider>.value(
      value: locationProvider,
      child: Provider<ApiService>.value(
        value: api,
        child: MaterialApp(
          navigatorObservers: [?observer],
          home: const BestPlacesScreen(listId: 'list-1'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders multiple ranked shops with complete and partial totals',
    (tester) async {
      final api = _FakeBestPlacesApi([_response()]);
      await _pump(tester, api);

      expect(find.text('Compare basket prices'), findsOneWidget);
      expect(find.text('2 shops have all 2 items'), findsOneWidget);
      expect(find.text('AEON BIG'), findsOneWidget);
      expect(find.text("LOTUS'S"), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ECONSAVE KLANG'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ECONSAVE KLANG'), findsOneWidget);
      expect(find.text('BEST PRICE'), findsOneWidget);
      expect(find.text('BASKET TOTAL'), findsNWidgets(2));
      expect(find.text('PARTIAL TOTAL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expanded card shows requested quantities, prices and missing items',
    (tester) async {
      final api = _FakeBestPlacesApi([_response()]);
      await _pump(tester, api);

      await tester.tap(find.text('AEON BIG'));
      await tester.pumpAndSettle();
      expect(find.text('RM2.90 x 1 | 31/07/2026'), findsOneWidget);
      expect(find.text('RM2.90'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('ECONSAVE KLANG'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('ECONSAVE KLANG'));
      await tester.pumpAndSettle();
      expect(find.text('Missing'), findsOneWidget);
      expect(find.text('AYAM BERSIH - STANDARD x1'), findsOneWidget);
    },
  );

  testWidgets('filter sheet applies once and resets pagination', (
    tester,
  ) async {
    final api = _FakeBestPlacesApi([_response(), _response(), _response()]);
    await _pump(tester, api);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Filter shops'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Complete basket'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
    await tester.pumpAndSettle();

    expect(api.calls, 2);
    expect(api.filtersSeen.last.coverage, BestPlacesCoverage.complete);
    expect(api.pagesSeen.last, 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Filter shops'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset filters'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
    await tester.pumpAndSettle();
    expect(api.calls, 3);
    expect(api.filtersSeen.last, isA<BestPlacesFilters>());
    expect(api.filtersSeen.last.isDefault, isTrue);
  });

  testWidgets('View store navigates using the stable premise code', (
    tester,
  ) async {
    final api = _FakeBestPlacesApi([_response()]);
    final observer = _RecordingNavigatorObserver();
    await _pump(tester, api, observer: observer);

    await tester.tap(find.text('AEON BIG'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(OutlinedButton, 'View store');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 500));

    expect(observer.lastPushed?.settings.arguments, 10);
  });

  testWidgets('Navigate uses the same stable premise code', (tester) async {
    final api = _FakeBestPlacesApi([_response()]);
    final observer = _RecordingNavigatorObserver();
    await _pump(tester, api, observer: observer);

    await tester.tap(find.text('AEON BIG'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Navigate');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 500));

    expect(observer.lastPushed?.settings.arguments, 10);
  });

  testWidgets('360px layout has no overflow', (tester) async {
    final api = _FakeBestPlacesApi([_response()]);
    await _pump(tester, api, size: const Size(360, 800));
    await tester.scrollUntilVisible(
      find.text('AEON BIG'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('AEON BIG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('location defaults to 10 km and radius changes reload ranking', (
    tester,
  ) async {
    final api = _FakeBestPlacesApi([
      _response(stores: [_complete(10, 'AEON BIG', 10.85, distanceKm: 4.5)]),
      _response(stores: [_complete(10, 'AEON BIG', 10.85, distanceKm: 4.5)]),
    ]);
    await _pump(tester, api, location: const UserLocation(3.139, 101.6869));

    expect(api.filtersSeen.first.radiusKm, 10);
    expect(find.text('4.5 km away'), findsOneWidget);
    await tester.tap(find.text('25 km'));
    await tester.pumpAndSettle();
    expect(api.filtersSeen.last.radiusKm, 25);
  });

  test('provider pagination deduplicates stores', () async {
    final api = _FakeBestPlacesApi([
      _response(
        stores: [_complete(10, 'AEON BIG', 10.85)],
        page: 1,
        totalPages: 2,
        totalResults: 2,
      ),
      _response(
        stores: [
          _complete(10, 'AEON BIG', 10.85),
          _complete(12, "LOTUS'S", 11.2),
        ],
        page: 2,
        totalPages: 2,
        totalResults: 2,
      ),
    ]);
    final provider = BestPlacesProvider(api, 'list-1');
    await provider.load();
    await provider.loadNextPage();

    expect(provider.stores.map((store) => store.premiseCode), [10, 12]);
    expect(api.pagesSeen, [1, 2]);
  });
}
