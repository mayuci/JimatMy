import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/latest_price.dart';
import 'package:jimatmy/models/price_trend.dart';
import 'package:jimatmy/screens/home_screen.dart';
import 'package:jimatmy/screens/search_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('home uses real featured codes and remains safe at 390px', (
    tester,
  ) async {
    final api = _PhaseTwoApi();
    await _pumpHome(tester, api);

    expect(find.text('Compare prices. Save every day.'), findsOneWidget);
    expect(find.text('Compare now'), findsOneWidget);
    expect(find.text('Lowest Prices Today'), findsOneWidget);
    expect(api.itemCodes, containsAll(<int>[1, 1559, 1109, 1582, 1440]));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    expect(find.text('Popular Categories'), findsOneWidget);
    expect(find.text('Household'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home search shows suggestions below the bar without navigating',
    (tester) async {
      final api = _PhaseTwoApi();
      await _pumpHome(tester, api);

      final field = find.byType(TextField);
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, 'egg');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.byType(SearchScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('search-item-action-1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('popular categories show product photos', (tester) async {
    final api = _PhaseTwoApi();
    await _pumpHome(tester, api);

    await tester.scrollUntilVisible(
      find.text('Vegetables'),
      450,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/products/brokoli.jpg',
      ),
      findsOneWidget,
    );
  });

  testWidgets('quick shortcuts have working destinations', (tester) async {
    var plannerOpened = false;
    await _pumpHome(
      tester,
      _PhaseTwoApi(),
      onOpenPlanner: () => plannerOpened = true,
    );

    await tester.tap(find.text('Shopping Planner'));
    expect(plannerOpened, isTrue);

    await tester.tap(find.text('Price Comparison'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(SearchScreen), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  ApiService api, {
  VoidCallback? onOpenPlanner,
}) async {
  tester.view
    ..physicalSize = const Size(780, 1688)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Provider<ApiService>.value(
      value: api,
      child: MaterialApp(home: HomeScreen(onOpenPlanner: onOpenPlanner)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _PhaseTwoApi extends ApiService {
  final List<int> itemCodes = [];

  @override
  Future<Item> getItem(int itemCode) async {
    itemCodes.add(itemCode);
    return _item(itemCode);
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
  }) async => ItemPage(items: [_item(1)], total: 1);

  @override
  Future<PriceTrend> getPriceTrend(
    int itemCode, {
    DateTime? from,
    DateTime? to,
  }) async => PriceTrend(
    item: _item(itemCode),
    points: [
      PriceTrendPoint(
        recordDate: DateTime(2026, 5, 1),
        averagePrice: 9,
        minimumPrice: 8,
        maximumPrice: 10,
      ),
      PriceTrendPoint(
        recordDate: DateTime(2026, 7, 31),
        averagePrice: 8.1,
        minimumPrice: 7.5,
        maximumPrice: 9,
      ),
    ],
  );
}

Item _item(int code) {
  const names = <int, String>{
    1: 'AYAM BERSIH - STANDARD',
    1559: 'KANGKUNG',
    1109: 'TELUR AYAM GRED A',
    1582: 'BERAS CAP JASMINE (SST5%)',
    1440: 'BAWANG BESAR IMPORT (INDIA)',
  };
  return Item(
    itemCode: code,
    itemName: names[code] ?? 'GROCERY ITEM',
    unit: '1 kg',
    itemGroup: 'BARANGAN SEGAR',
    itemCategory: 'AYAM',
    latestPrices: const [
      LatestPrice(
        premiseCode: 101,
        premiseName: 'PASAR TEST',
        address: 'Kuala Lumpur',
        state: 'W.P. Kuala Lumpur',
        district: 'Kuala Lumpur',
        price: 7.95,
        recordDate: '2026-08-01',
      ),
    ],
  );
}
