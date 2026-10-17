import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/best_places_models.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/planner_models.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/providers/planner_provider.dart';
import 'package:jimatmy/screens/shopping_list_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/widgets/shopping_list_item_widget.dart';
import 'package:jimatmy/widgets/item_image_widget.dart';
import 'package:provider/provider.dart';

const _chicken = ShoppingListItem(
  listItemId: 'i1',
  itemCode: 1,
  itemName: 'AYAM BERSIH - STANDARD',
  unit: '1 kg',
  quantity: 1,
  isChecked: false,
  bestPrice: 7.95,
  estimatedLineTotal: 7.95,
  cheapestPremise: CheapestPremise(premiseName: 'LOTUSS STORES'),
);

const _rice = ShoppingListItem(
  listItemId: 'i2',
  itemCode: 2,
  itemName: 'BERAS CAP JASMINE',
  unit: '10 kg',
  quantity: 2,
  isChecked: true,
  bestPrice: 26.00,
  estimatedLineTotal: 52.00,
  cheapestPremise: CheapestPremise(premiseName: '99 SPEED MART'),
);

const _unavailable = ShoppingListItem(
  listItemId: 'i3',
  itemCode: 3,
  itemName: 'UNAVAILABLE ITEM',
  unit: '1 unit',
  quantity: 1,
  isChecked: false,
  bestPrice: null,
  estimatedLineTotal: null,
  cheapestPremise: null,
);

class _FakePlannerApi extends ApiService {
  _FakePlannerApi(this.detail, {this.failLoadWith});

  ShoppingListDetail detail;
  ApiException? failLoadWith;
  int listLoadCount = 0;
  final List<String> itemQueries = <String>[];
  final List<String> updatedQuantities = <String>[];

  ShoppingListDetail _recompute(List<ShoppingListItem> items) =>
      ShoppingListDetail(
        shoppingListId: detail.shoppingListId,
        name: detail.name,
        itemCount: items.length,
        completedItemCount: items.where((item) => item.isChecked).length,
        estimatedTotal: items.fold(
          0.0,
          (sum, item) => sum + (item.estimatedLineTotal ?? 0),
        ),
        items: items,
      );

  ShoppingListItem _copy(
    ShoppingListItem item, {
    double? quantity,
    bool? isChecked,
  }) => ShoppingListItem(
    listItemId: item.listItemId,
    itemCode: item.itemCode,
    itemName: item.itemName,
    unit: item.unit,
    quantity: quantity ?? item.quantity,
    isChecked: isChecked ?? item.isChecked,
    bestPrice: item.bestPrice,
    estimatedLineTotal: item.bestPrice == null
        ? null
        : (quantity ?? item.quantity) * item.bestPrice!,
    cheapestPremise: item.cheapestPremise,
  );

  @override
  Future<ShoppingListDetail> getShoppingList(String listId) async {
    listLoadCount += 1;
    final error = failLoadWith;
    if (error != null) throw error;
    return detail;
  }

  @override
  Future<PlannerOverview> getPlannerOverview() async => PlannerOverview(
    month: '2026-08',
    lists: const [],
    plannerEstimatedTotal: detail.estimatedTotal,
    budget: const MonthlyBudget(month: '2026-08', amount: 200),
    remainingBudget: 200 - detail.estimatedTotal,
    overBudget: detail.estimatedTotal > 200,
  );

  @override
  Future<void> addShoppingListItem(
    String listId,
    int itemCode,
    double quantity,
  ) async {
    if (detail.items.any((item) => item.itemCode == itemCode)) {
      throw ApiException(
        'This item is already in the list',
        code: 'DUPLICATE_LIST_ITEM',
        statusCode: 409,
      );
    }
    detail = _recompute([
      ...detail.items,
      ShoppingListItem(
        listItemId: 'new-$itemCode',
        itemCode: itemCode,
        itemName: 'ITEM $itemCode',
        unit: '1 unit',
        quantity: quantity,
        isChecked: false,
        bestPrice: 7.95,
        estimatedLineTotal: 7.95 * quantity,
        cheapestPremise: const CheapestPremise(premiseName: 'LOTUSS STORES'),
      ),
    ]);
  }

  @override
  Future<void> updateShoppingListItem(
    String listId,
    String listItemId, {
    double? quantity,
    bool? isChecked,
  }) async {
    updatedQuantities.add('$listItemId q=$quantity checked=$isChecked');
    detail = _recompute([
      for (final item in detail.items)
        if (item.listItemId == listItemId)
          _copy(item, quantity: quantity, isChecked: isChecked)
        else
          item,
    ]);
  }

  @override
  Future<void> deleteShoppingListItem(String listId, String listItemId) async {
    detail = _recompute([
      for (final item in detail.items)
        if (item.listItemId != listItemId) item,
    ]);
  }

  @override
  Future<ItemPage> getItems({
    String query = '',
    required int limit,
    required int offset,
    String? category,
    String? state,
    String? district,
    bool pricedOnly = false,
  }) async {
    itemQueries.add(query);
    return ItemPage(
      items: const [
        Item(
          itemCode: 1,
          itemName: 'AYAM BERSIH - STANDARD',
          unit: '1 kg',
          itemGroup: 'BARANGAN SEGAR',
          itemCategory: 'AYAM',
        ),
      ],
      total: 1,
    );
  }

  @override
  Future<BestPlacesResponse> getBestPlaces(
    String listId, {
    BestPlacesFilters filters = const BestPlacesFilters(),
    int page = 1,
    int limit = 20,
  }) async {
    final active = detail.items.where((item) => !item.isChecked).toList();
    final stores = active.isEmpty
        ? <BasketStore>[]
        : [
            BasketStore(
              premiseCode: 1,
              premiseName: 'LOTUSS STORES',
              premiseType: 'HYPERMARKET',
              address: 'Official address',
              district: 'Petaling',
              state: 'Selangor',
              coveredItemCount: active.length,
              totalItemCount: active.length,
              isComplete: true,
              basketTotal: detail.estimatedTotal,
              partialTotal: null,
              latestPriceDate: '2026-07-31',
              items: [
                for (final item in active)
                  if (item.bestPrice != null)
                    BasketStoreItem(
                      itemCode: item.itemCode,
                      itemName: item.itemName,
                      unit: item.unit,
                      requestedQuantity: item.quantity,
                      unitPrice: item.bestPrice!,
                      lineTotal: item.bestPrice! * item.quantity,
                      priceDate: '2026-07-31',
                    ),
              ],
              missingItems: const [],
            ),
          ];
    return BestPlacesResponse(
      listId: listId,
      listName: detail.name,
      itemCount: active.length,
      requestedItems: [
        for (final item in active)
          RequestedBasketItem(
            itemCode: item.itemCode,
            itemName: item.itemName,
            unit: item.unit,
            requestedQuantity: item.quantity,
          ),
      ],
      summary: BestPlacesSummary(
        totalPremises: stores.length,
        completePremises: stores.length,
        incompletePremises: 0,
        lowestCompleteTotal: stores.isEmpty ? null : detail.estimatedTotal,
        highestCompleteTotal: stores.isEmpty ? null : detail.estimatedTotal,
      ),
      stores: stores,
      twoStoreCombination: null,
      pagination: BestPlacesPagination(
        page: page,
        limit: limit,
        totalResults: stores.length,
        totalPages: stores.isEmpty ? 0 : 1,
      ),
      filterOptions: const BestPlacesFilterOptions(
        states: ['Selangor'],
        districts: [DistrictOption(state: 'Selangor', district: 'Petaling')],
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakePlannerApi api, {
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = AuthProvider(api)..isRestoring = false;
  final planner = PlannerProvider(api);
  await planner.load();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<PlannerProvider>.value(value: planner),
      ],
      child: const MaterialApp(home: ShoppingListScreen(listId: 'list-1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty shopping list renders full UI without a blank page', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 0,
        completedItemCount: 0,
        estimatedTotal: 0,
        items: const [],
      ),
    );
    await _pump(tester, api);

    expect(tester.takeException(), isNull);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Weekly groceries'), findsOneWidget);
    expect(find.text('My list'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('0 items'), findsOneWidget);
    expect(find.text('Your list is empty'), findsOneWidget);
    expect(find.text('Estimated total'), findsOneWidget);
    expect(find.text('RM 0.00'), findsOneWidget);
    expect(find.text('RM 200.00 within budget'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Add item'), findsOneWidget);

    // The body list must have real height (regression: was 0 → blank page).
    final listView = find.byType(ListView).first;
    expect(tester.getSize(listView).height, greaterThan(100));
  });

  testWidgets('list with items shows priced and unavailable rows', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 2,
        completedItemCount: 0,
        estimatedTotal: 7.95,
        items: const [_chicken, _unavailable],
      ),
    );
    await _pump(tester, api);

    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.text('Best price RM 7.95'), findsOneWidget);
    expect(find.text('LOTUSS STORES'), findsOneWidget);
    expect(find.text('UNAVAILABLE ITEM'), findsOneWidget);
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.byType(ItemImage), findsNWidgets(2));
    expect(
      find.ancestor(
        of: find.byType(ShoppingListItemWidget).first,
        matching: find.byType(Card),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completed tab shows checked items and hides them from My list', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 2,
        completedItemCount: 1,
        estimatedTotal: 59.95,
        items: const [_chicken, _rice],
      ),
    );
    await _pump(tester, api);

    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.text('BERAS CAP JASMINE'), findsNothing);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('BERAS CAP JASMINE'), findsOneWidget);
    expect(find.text('AYAM BERSIH - STANDARD'), findsNothing);
  });

  testWidgets('quantity plus increases and minus is disabled at one', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 1,
        completedItemCount: 0,
        estimatedTotal: 7.95,
        items: const [_chicken],
      ),
    );
    await _pump(tester, api);

    final minus = find.widgetWithIcon(IconButton, Icons.remove);
    final plus = find.widgetWithIcon(IconButton, Icons.add);
    expect(tester.widget<IconButton>(minus).onPressed, isNull);

    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(api.updatedQuantities, contains('i1 q=2.0 checked=null'));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('removing an item asks for confirmation and deletes it', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 2,
        completedItemCount: 1,
        estimatedTotal: 59.95,
        items: const [_chicken, _rice],
      ),
    );
    await _pump(tester, api);

    await tester.tap(find.byTooltip('Remove item'));
    await tester.pumpAndSettle();
    expect(find.text('Remove item?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(find.text('AYAM BERSIH - STANDARD'), findsNothing);
  });

  testWidgets('completing and restoring an item keeps it visible', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 2,
        completedItemCount: 1,
        estimatedTotal: 59.95,
        items: const [_chicken, _rice],
      ),
    );
    await _pump(tester, api);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(api.updatedQuantities, contains('i1 q=null checked=true'));
    expect(find.text('AYAM BERSIH - STANDARD'), findsNothing);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.text('BERAS CAP JASMINE'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(api.updatedQuantities, contains('i1 q=null checked=false'));
  });

  testWidgets('over budget shows an over-budget message', (tester) async {
    const expensive = ShoppingListItem(
      listItemId: 'x',
      itemCode: 9,
      itemName: 'EXPENSIVE ITEM',
      unit: '1 unit',
      quantity: 1,
      isChecked: false,
      bestPrice: 250,
      estimatedLineTotal: 250,
      cheapestPremise: CheapestPremise(premiseName: 'STORE'),
    );
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 1,
        completedItemCount: 0,
        estimatedTotal: 250,
        items: const [expensive],
      ),
    );
    await _pump(tester, api);

    expect(find.text('RM 50.00 over budget'), findsOneWidget);
  });

  testWidgets('list load error shows retry', (tester) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 0,
        completedItemCount: 0,
        estimatedTotal: 0,
        items: const [],
      ),
      failLoadWith: const ApiException('Server unavailable', statusCode: 500),
    );
    await _pump(tester, api);

    expect(find.text("Couldn't load this shopping list."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('not found shows back to planner', (tester) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 0,
        completedItemCount: 0,
        estimatedTotal: 0,
        items: const [],
      ),
      failLoadWith: const ApiException(
        'Shopping list was not found',
        code: 'SHOPPING_LIST_NOT_FOUND',
        statusCode: 404,
      ),
    );
    await _pump(tester, api);

    expect(find.text('Shopping list not found.'), findsOneWidget);
    expect(find.text('Back to planner'), findsOneWidget);
  });

  testWidgets('add item sheet debounces search', (tester) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 0,
        completedItemCount: 0,
        estimatedTotal: 0,
        items: const [],
      ),
    );
    await _pump(tester, api);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Search PriceCatcher items'), findsOneWidget);
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);

    final before = api.itemQueries.length;
    await tester.enterText(find.byType(TextField), 'ayam');
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.itemQueries.length, before);
    await tester.pump(const Duration(milliseconds: 200));
    expect(api.itemQueries.length, before + 1);
    expect(api.itemQueries.last, 'ayam');
  });

  testWidgets('duplicate item add shows the existing business rule message', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 1,
        completedItemCount: 0,
        estimatedTotal: 7.95,
        items: const [_chicken],
      ),
    );
    await _pump(tester, api);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add item'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('This item is already in the list'), findsOneWidget);
  });

  testWidgets('layout holds at 360x800 without overflow', (tester) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 2,
        completedItemCount: 0,
        estimatedTotal: 7.95,
        items: const [_chicken, _unavailable],
      ),
    );
    await _pump(tester, api, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.byType(ShoppingListItemWidget), findsWidgets);
  });

  testWidgets('layout holds at 412x915 without overflow', (tester) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 2,
        completedItemCount: 0,
        estimatedTotal: 7.95,
        items: const [_chicken, _unavailable],
      ),
    );
    await _pump(tester, api, size: const Size(412, 915));
    expect(tester.takeException(), isNull);
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.byType(ShoppingListItemWidget), findsWidgets);
  });

  testWidgets('find best places opens the whole-list recommendation', (
    tester,
  ) async {
    final api = _FakePlannerApi(
      ShoppingListDetail(
        shoppingListId: 'list-1',
        name: 'Weekly groceries',
        itemCount: 1,
        completedItemCount: 0,
        estimatedTotal: 7.95,
        items: const [_chicken],
      ),
    );
    await _pump(tester, api);
    await tester.tap(find.widgetWithText(FilledButton, 'Find best places'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Shop comparison'), findsOneWidget);
    expect(find.text('LOTUSS STORES'), findsOneWidget);
    expect(find.text('All 1 items available'), findsOneWidget);
  });
}
