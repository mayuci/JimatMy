import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/price_trend.dart';
import 'package:jimatmy/screens/price_trend_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/services/item_image_resolver.dart';
import 'package:jimatmy/widgets/item_image_widget.dart';

Map<String, dynamic> _itemJson() => {
  'itemCode': 1,
  'itemName': 'AYAM BERSIH - STANDARD',
  'unit': '1kg',
  'itemGroup': 'BARANGAN SEGAR',
  'itemCategory': 'AYAM',
};

void main() {
  test('trend parses, sorts, and calculates summary values', () {
    final trend = PriceTrend.fromJson({
      'item': _itemJson(),
      'trends': [
        {
          'recordDate': '2026-07-31',
          'averagePrice': 9.50,
          'minimumPrice': 8.20,
          'maximumPrice': 11.20,
        },
        {
          'recordDate': '2026-05-02',
          'averagePrice': 9.00,
          'minimumPrice': 8.00,
          'maximumPrice': 10.50,
        },
      ],
    });

    expect(trend.points.first.recordDate, DateTime(2026, 5, 2));
    expect(trend.absoluteChange, closeTo(0.50, 0.001));
    expect(trend.percentageChange, closeTo(5.56, 0.01));
    expect(trend.lowestDailyPrice, 8.00);
    expect(trend.highestDailyPrice, 11.20);
    expect(trend.trendLabel, 'Increased');
  });

  test('stable and insufficient trends are neutral', () {
    final onePoint = PriceTrend(
      item: Item.fromJson(_itemJson()),
      points: [
        PriceTrendPoint(
          recordDate: DateTime(2026, 7, 31),
          averagePrice: 9,
          minimumPrice: 8,
          maximumPrice: 10,
        ),
      ],
    );
    expect(onePoint.absoluteChange, isNull);
    expect(onePoint.percentageChange, isNull);
    expect(onePoint.trendLabel, 'Stable');
  });

  testWidgets('screen displays empty trend state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PriceTrendScreen(
          itemCode: 1,
          apiService: _FakeTrendApi(_emptyTrend()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No trend data'), findsOneWidget);
  });

  testWidgets('screen displays insufficient trend state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PriceTrendScreen(
          itemCode: 1,
          apiService: _FakeTrendApi(_singlePointTrend()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('More history needed'), findsOneWidget);
  });

  testWidgets('screen displays API error and retry state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PriceTrendScreen(itemCode: 1, apiService: _FakeTrendApi(null)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Trend unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('screen renders chart summary and reloads selected range', (
    tester,
  ) async {
    final api = _FakeTrendApi(_twoPointTrend());
    await tester.pumpWidget(
      MaterialApp(home: PriceTrendScreen(itemCode: 1, apiService: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Price summary', skipOffstage: false), findsOneWidget);
    expect(find.text('Price insight', skipOffstage: false), findsOneWidget);
    expect(api.calls, 1);

    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();
    expect(api.calls, 1);
  });

  testWidgets('trend header uses shared image without refetching data', (
    tester,
  ) async {
    final api = _FakeTrendApi(_twoPointTrend());
    final resolver = ItemImageResolver.fromAssetPaths(const [
      '${featuredItemImageDirectory}ayam_bersih.webp',
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: PriceTrendScreen(
          itemCode: 1,
          itemName: 'AYAM BERSIH - STANDARD',
          unit: '1kg',
          category: 'AYAM',
          group: 'BARANGAN SEGAR',
          imageResolver: resolver,
          apiService: api,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<ItemImage>(find.byType(ItemImage));
    expect(image.itemCode, 1);
    expect(image.itemName, 'AYAM BERSIH - STANDARD');
    expect(image.width, 58);
    expect(image.height, 58);
    expect(
      find.byKey(
        const ValueKey('item-image-assets/images/featured/ayam_bersih.webp'),
      ),
      findsOneWidget,
    );
    expect(api.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long trend item identity remains safe on a narrow screen', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final longItem = Item(
      itemCode: 700,
      itemName: 'VERY LONG OFFICIAL GROCERY PRODUCT NAME WITH PACKAGE DETAILS',
      unit: '1 PACKET',
      itemGroup: 'BARANGAN KERING',
      itemCategory: 'LAIN-LAIN',
    );
    final api = _FakeTrendApi(
      PriceTrend(item: longItem, points: _twoPointTrend().points),
    );
    await tester.pumpWidget(
      MaterialApp(home: PriceTrendScreen(itemCode: 700, apiService: api)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItemImage), findsOneWidget);
    expect(api.calls, 1);
    expect(tester.takeException(), isNull);
  });
}

PriceTrend _emptyTrend() =>
    PriceTrend(item: Item.fromJson(_itemJson()), points: const []);

PriceTrend _singlePointTrend() => PriceTrend(
  item: Item.fromJson(_itemJson()),
  points: [
    PriceTrendPoint(
      recordDate: DateTime(2026, 7, 31),
      averagePrice: 9,
      minimumPrice: 8,
      maximumPrice: 10,
    ),
  ],
);

PriceTrend _twoPointTrend() => PriceTrend(
  item: Item.fromJson(_itemJson()),
  points: [
    PriceTrendPoint(
      recordDate: DateTime(2026, 5, 22),
      averagePrice: 9,
      minimumPrice: 8,
      maximumPrice: 10,
    ),
    PriceTrendPoint(
      recordDate: DateTime(2026, 7, 2),
      averagePrice: 9.2,
      minimumPrice: 8.2,
      maximumPrice: 10.5,
    ),
    PriceTrendPoint(
      recordDate: DateTime(2026, 7, 31),
      averagePrice: 9.5,
      minimumPrice: 8.5,
      maximumPrice: 11,
    ),
  ],
);

class _FakeTrendApi extends ApiService {
  _FakeTrendApi(this.result);
  final PriceTrend? result;
  int calls = 0;

  @override
  Future<PriceTrend> getPriceTrend(
    int itemCode, {
    DateTime? from,
    DateTime? to,
  }) async {
    calls += 1;
    if (result == null) throw const ApiException('Test API error');
    return result!;
  }
}
