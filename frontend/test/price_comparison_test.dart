import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/latest_price.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/models/price_comparison.dart';
import 'package:jimatmy/screens/price_comparison_screen.dart';
import 'package:jimatmy/screens/store_detail_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  test('comparison parses, sorts, and calculates potential saving', () {
    final comparison = PriceComparison.fromJson({
      'item': {
        'itemCode': 1,
        'itemName': 'AYAM BERSIH - STANDARD',
        'unit': '1kg',
        'itemGroup': 'BARANGAN SEGAR',
        'itemCategory': 'AYAM',
      },
      'cheapestOption': {
        'premiseCode': 176,
        'premiseName': "LOTUS'S CHERAS",
        'price': 8.49,
        'recordDate': '2026-08-01',
      },
      'prices': [
        {
          'premiseCode': 136,
          'premiseName': 'THE STORE ( PUDU PLAZA )',
          'address': 'JALAN DAVIS',
          'state': 'W.P. Kuala Lumpur',
          'district': 'Cheras',
          'price': 10.99,
          'recordDate': '2026-08-01',
        },
        {
          'premiseCode': 176,
          'premiseName': "LOTUS'S CHERAS",
          'address': 'TAMAN MIDAH',
          'state': 'W.P. Kuala Lumpur',
          'district': 'Cheras',
          'price': 8.49,
          'recordDate': '2026-08-01',
        },
      ],
    });

    expect(comparison.item.itemCode, 1);
    expect(comparison.cheapestOption?.premiseCode, 176);
    expect(comparison.prices.first.premiseCode, 176);
    expect(comparison.prices.first.price, 8.49);
    expect(comparison.prices.last.price, 10.99);
    expect(comparison.savingDifference, closeTo(2.50, 0.001));
  });

  test('comparison handles an empty price response', () {
    final comparison = PriceComparison.fromJson({
      'item': {
        'itemCode': 1,
        'itemName': 'AYAM BERSIH - STANDARD',
        'unit': '1kg',
        'itemGroup': 'BARANGAN SEGAR',
        'itemCategory': 'AYAM',
      },
      'cheapestOption': null,
      'prices': <dynamic>[],
    });

    expect(comparison.prices, isEmpty);
    expect(comparison.cheapestOption, isNull);
    expect(comparison.savingDifference, isNull);
  });

  testWidgets('duplicate premise names navigate by the ranked price code', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _ComparisonApi();
    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: api,
        child: const MaterialApp(home: PriceComparisonScreen(itemCode: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add to Planner'), findsOneWidget);
    expect(
      find.text('Potential saving RM 2.50 against the highest shown price'),
      findsOneWidget,
    );

    final secondRank = find.text('#2');
    await tester.scrollUntilVisible(secondRank, 180);
    await tester.pumpAndSettle();
    final priceCard = find.ancestor(
      of: secondRank,
      matching: find.byType(InkWell),
    );
    await tester.tap(priceCard);
    await tester.pumpAndSettle();

    final store = tester.widget<StoreDetailScreen>(
      find.byType(StoreDetailScreen),
    );
    expect(store.requestedPremiseCode, 136);
    expect(api.requestedPremiseCodes, [136]);
    expect(tester.takeException(), isNull);
  });
}

class _ComparisonApi extends ApiService {
  final List<int> requestedPremiseCodes = [];

  @override
  Future<PriceComparison> getPriceComparison(
    int itemCode, {
    String? state,
    String? district,
  }) async => const PriceComparison(
    item: Item(
      itemCode: 1,
      itemName: 'AYAM BERSIH - STANDARD',
      unit: '1kg',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'AYAM',
    ),
    cheapestOption: CheapestOption(
      premiseCode: 176,
      premiseName: 'DUPLICATE STORE',
      price: 8.49,
      recordDate: '2026-08-01',
    ),
    prices: [
      LatestPrice(
        premiseCode: 176,
        premiseName: 'DUPLICATE STORE',
        address: 'FIRST BRANCH',
        state: 'W.P. Kuala Lumpur',
        district: 'Cheras',
        price: 8.49,
        recordDate: '2026-08-01',
      ),
      LatestPrice(
        premiseCode: 136,
        premiseName: 'DUPLICATE STORE',
        address: 'SECOND BRANCH',
        state: 'W.P. Kuala Lumpur',
        district: 'Cheras',
        price: 10.99,
        recordDate: '2026-08-01',
      ),
    ],
  );

  @override
  Future<Premise> getPremise(int premiseCode) async {
    requestedPremiseCodes.add(premiseCode);
    return Premise(
      premiseCode: premiseCode,
      premiseName: 'DUPLICATE STORE',
      address: premiseCode == 136 ? 'SECOND BRANCH' : 'FIRST BRANCH',
      postcode: null,
      premiseType: 'Store',
      district: 'Cheras',
      state: 'W.P. Kuala Lumpur',
      latitude: null,
      longitude: null,
    );
  }
}
