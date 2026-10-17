import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/latest_price.dart';
import 'package:jimatmy/models/price_trend.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/screens/home_screen.dart';
import 'package:jimatmy/screens/item_detail_screen.dart';
import 'package:jimatmy/screens/search_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('typing egg shows matching item suggestions on the home page', (
    tester,
  ) async {
    final api = _SuggestionApi();
    await _pumpHome(tester, api);

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, 'egg');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(api.lastQuery, 'egg');
    expect(find.byType(SearchScreen), findsNothing);
    expect(
      find.byKey(const ValueKey('search-item-action-1109')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('search-item-action-1110')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home suggestion tap opens the item detail instead of search page',
    (tester) async {
      final api = _SuggestionApi();
      await _pumpHome(tester, api);

      final field = find.byType(TextField);
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, 'egg');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('search-item-action-1109')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(find.byType(SearchScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home search shows a no-results hint for unmatched text', (
    tester,
  ) async {
    final api = _SuggestionApi();
    await _pumpHome(tester, api);

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, 'zzz');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('No matching items'), findsOneWidget);
    expect(find.byType(SearchScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHome(WidgetTester tester, ApiService api) async {
  tester.view
    ..physicalSize = const Size(780, 1688)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _SuggestionApi extends ApiService {
  String? lastQuery;

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
    lastQuery = query;
    if (query.toLowerCase().contains('egg')) {
      return ItemPage(
        items: [_egg(1109, 'TELUR AYAM GRED A'), _egg(1110, 'TELUR ITIK')],
        total: 2,
      );
    }
    return const ItemPage(items: [], total: 0);
  }

  @override
  Future<Item> getItem(int itemCode) async =>
      _egg(itemCode, itemCode == 1109 ? 'TELUR AYAM GRED A' : 'TELUR ITIK');

  @override
  Future<PriceTrend> getPriceTrend(
    int itemCode, {
    DateTime? from,
    DateTime? to,
  }) async =>
      PriceTrend(item: _egg(itemCode, 'TELUR AYAM GRED A'), points: const []);
}

Item _egg(int code, String name) => Item(
  itemCode: code,
  itemName: name,
  unit: '10 biji',
  itemGroup: 'BARANGAN SEGAR',
  itemCategory: 'TELUR',
  latestPrices: const [
    LatestPrice(
      premiseCode: 101,
      premiseName: 'PASAR TEST',
      address: 'Kuala Lumpur',
      state: 'W.P. Kuala Lumpur',
      district: 'Kuala Lumpur',
      price: 13.5,
      recordDate: '2026-08-01',
    ),
  ],
);
