import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/latest_price.dart';
import 'package:jimatmy/models/price_comparison.dart';
import 'package:jimatmy/models/price_trend.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/providers/planner_provider.dart';
import 'package:jimatmy/providers/price_comparison_provider.dart';
import 'package:jimatmy/providers/price_trend_provider.dart';
import 'package:jimatmy/screens/price_comparison_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  test(
    'comparison filters preserve official state and district values',
    () async {
      final api = _PhaseFourApi();
      final provider = PriceComparisonProvider(api, 1);

      await provider.load();
      await provider.selectState('Selangor');
      expect(api.comparisonCalls.last, ('Selangor', null));
      expect(provider.districts, ['Petaling']);

      await provider.selectDistrict('Petaling');
      expect(api.comparisonCalls.last, ('Selangor', 'Petaling'));
    },
  );

  test(
    'trend periods use one real history response and disable six months',
    () async {
      final api = _PhaseFourApi();
      final provider = PriceTrendProvider(api, 1);

      await provider.load();
      expect(provider.isRangeAvailable(TrendRange.sevenDays), isTrue);
      expect(provider.isRangeAvailable(TrendRange.thirtyDays), isTrue);
      expect(provider.isRangeAvailable(TrendRange.threeMonths), isTrue);
      expect(provider.isRangeAvailable(TrendRange.sixMonths), isFalse);

      provider.selectRange(TrendRange.thirtyDays);
      expect(provider.trend?.points.length, 30);
      expect(api.trendCalls, 1);
    },
  );

  testWidgets('logged-out planner action gives a friendly login prompt', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _PhaseFourApi();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
          ChangeNotifierProvider(create: (_) => PlannerProvider(api)),
        ],
        child: const MaterialApp(home: PriceComparisonScreen(itemCode: 1)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Planner'));
    await tester.pumpAndSettle();
    expect(find.text('Log in to use Planner'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('find best places destination renders results top-to-bottom', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _PhaseFourApi();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
          ChangeNotifierProvider(create: (_) => PlannerProvider(api)),
        ],
        child: const MaterialApp(home: PriceComparisonScreen(itemCode: 1)),
      ),
    );
    await tester.pumpAndSettle();

    // Regression: the destination used to crash with "Incorrect use of
    // ParentDataWidget" and render a blank page. It must now start at the
    // top with an app bar, results, and a real body height.
    expect(tester.takeException(), isNull);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Price comparison'), findsOneWidget);
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.text('Best price'), findsOneWidget);
    expect(find.text('PASAR SEGAR'), findsWidgets);
    expect(find.text('2 premise prices'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add to Planner'), findsOneWidget);
    expect(
      tester.getSize(find.byType(ListView).first).height,
      greaterThan(100),
    );
  });

  testWidgets('find best places destination holds at 360x800', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _PhaseFourApi();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
          ChangeNotifierProvider(create: (_) => PlannerProvider(api)),
        ],
        child: const MaterialApp(home: PriceComparisonScreen(itemCode: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add to Planner'), findsOneWidget);
  });
}

class _PhaseFourApi extends ApiService {
  final List<(String?, String?)> comparisonCalls = [];
  int trendCalls = 0;

  @override
  Future<PriceComparison> getPriceComparison(
    int itemCode, {
    String? state,
    String? district,
  }) async {
    comparisonCalls.add((state, district));
    return PriceComparison(
      item: _item,
      cheapestOption: const CheapestOption(
        premiseCode: 10,
        premiseName: 'PASAR SEGAR',
        price: 8.5,
        recordDate: '2026-07-31',
      ),
      prices: const [
        LatestPrice(
          premiseCode: 10,
          premiseName: 'PASAR SEGAR',
          address: 'JALAN UTAMA',
          state: 'Selangor',
          district: 'Petaling',
          price: 8.5,
          recordDate: '2026-07-31',
        ),
        LatestPrice(
          premiseCode: 11,
          premiseName: 'PASAR RAYA',
          address: 'JALAN DUA',
          state: 'Selangor',
          district: 'Petaling',
          price: 9.5,
          recordDate: '2026-07-31',
        ),
      ],
    );
  }

  @override
  Future<PriceTrend> getPriceTrend(
    int itemCode, {
    DateTime? from,
    DateTime? to,
  }) async {
    trendCalls++;
    final first = DateTime(2026, 5, 2);
    return PriceTrend(
      item: _item,
      points: List.generate(91, (index) {
        final price = 9 + index / 100;
        return PriceTrendPoint(
          recordDate: first.add(Duration(days: index)),
          averagePrice: price,
          minimumPrice: price - .5,
          maximumPrice: price + .5,
        );
      }),
    );
  }
}

const _item = Item(
  itemCode: 1,
  itemName: 'AYAM BERSIH - STANDARD',
  unit: '1 kg',
  itemGroup: 'BARANGAN SEGAR',
  itemCategory: 'AYAM',
);
