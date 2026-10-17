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
  testWidgets('home category opens Search with the selected official filter', (
    tester,
  ) async {
    final api = _HomeApi();
    await _pumpHome(tester, api);

    await tester.scrollUntilVisible(
      find.text('Vegetables'),
      450,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Vegetables'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(api.requestedCategory, 'vegetables');
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
    Provider<ApiService>.value(
      value: api,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

class _HomeApi extends ApiService {
  String? requestedCategory;

  @override
  Future<Item> getItem(int itemCode) async => _item(itemCode);

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
    requestedCategory = category;
    return ItemPage(items: [_item(1559)], total: 1);
  }

  @override
  Future<PriceTrend> getPriceTrend(
    int itemCode, {
    DateTime? from,
    DateTime? to,
  }) async => PriceTrend(item: _item(itemCode), points: const []);
}

Item _item(int code) => Item(
  itemCode: code,
  itemName: code == 1 ? 'AYAM BERSIH - STANDARD' : 'KANGKUNG',
  unit: '1 kg',
  itemGroup: 'BARANGAN SEGAR',
  itemCategory: code == 1 ? 'AYAM' : 'SAYUR-SAYURAN',
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
