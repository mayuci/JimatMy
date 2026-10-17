import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/latest_price.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/screens/item_detail_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/widgets/promotion_carousel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('egg slide uses official API item and price data', (
    tester,
  ) async {
    final api = _PromotionApi();
    await _pumpCarousel(tester, api);

    await _swipeToNext(tester);
    await _swipeToNext(tester);

    expect(find.text('TELUR AYAM GRED A'), findsOneWidget);
    expect(find.text('30 biji'), findsOneWidget);
    expect(find.text('From RM 8.00'), findsOneWidget);
    expect(find.text('PASAR PUDU'), findsOneWidget);
  });

  testWidgets('Compare now opens the correct item detail', (tester) async {
    final api = _PromotionApi();
    await _pumpCarousel(tester, api);

    await tester.tap(find.text('Compare now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final detail = tester.widget<ItemDetailScreen>(
      find.byType(ItemDetailScreen),
    );
    expect(detail.itemCode, 1);
  });

  testWidgets('card tap opens the correct item detail', (tester) async {
    final api = _PromotionApi();
    await _pumpCarousel(tester, api);

    await tester.tap(find.text('AYAM BERSIH - STANDARD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final detail = tester.widget<ItemDetailScreen>(
      find.byType(ItemDetailScreen),
    );
    expect(detail.itemCode, 1);
  });

  testWidgets('horizontal swipe changes slides without navigating', (
    tester,
  ) async {
    final api = _PromotionApi();
    await _pumpCarousel(tester, api);

    await _swipeToNext(tester);

    expect(find.text('KANGKUNG'), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
  });
}

Future<void> _pumpCarousel(WidgetTester tester, ApiService api) async {
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
      child: MaterialApp(
        home: Scaffold(
          body: Container(
            width: 390,
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF0D5B3D),
            child: PromotionCarousel(apiService: api),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _swipeToNext(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-300, 0));
  await tester.pump(const Duration(milliseconds: 400));
}

class _PromotionApi extends ApiService {
  static const _items = {
    1: Item(
      itemCode: 1,
      itemName: 'AYAM BERSIH - STANDARD',
      unit: '1kg',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'AYAM',
      latestPrices: [
        LatestPrice(
          premiseCode: 1,
          premiseName: 'LOTUSS STORES',
          address: 'Kuala Lumpur',
          state: 'W.P. Kuala Lumpur',
          district: 'Kuala Lumpur',
          price: 7.95,
          recordDate: '2026-08-01',
        ),
      ],
    ),
    1559: Item(
      itemCode: 1559,
      itemName: 'KANGKUNG',
      unit: '1kg',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'SAYUR-SAYURAN',
      latestPrices: [
        LatestPrice(
          premiseCode: 2,
          premiseName: 'PASARAYA BORONG BIG',
          address: 'Selangor',
          state: 'Selangor',
          district: 'Petaling',
          price: 1.99,
          recordDate: '2026-08-01',
        ),
      ],
    ),
    1109: Item(
      itemCode: 1109,
      itemName: 'TELUR AYAM GRED A',
      unit: '30 biji',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'TELUR',
      latestPrices: [
        LatestPrice(
          premiseCode: 3,
          premiseName: 'PASAR PUDU',
          address: 'Kuala Lumpur',
          state: 'W.P. Kuala Lumpur',
          district: 'Kuala Lumpur',
          price: 8,
          recordDate: '2026-08-01',
        ),
      ],
    ),
    1582: Item(
      itemCode: 1582,
      itemName: 'BERAS CAP JASMINE (SST5%)',
      unit: '10 kg',
      itemGroup: 'BARANGAN BERBUNGKUS',
      itemCategory: 'BERAS',
      latestPrices: [
        LatestPrice(
          premiseCode: 4,
          premiseName: '99 SPEED MART',
          address: 'Kuala Lumpur',
          state: 'W.P. Kuala Lumpur',
          district: 'Kuala Lumpur',
          price: 26,
          recordDate: '2026-08-01',
        ),
      ],
    ),
    1440: Item(
      itemCode: 1440,
      itemName: 'BAWANG BESAR IMPORT (INDIA)',
      unit: '1kg',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'BAWANG',
      latestPrices: [
        LatestPrice(
          premiseCode: 5,
          premiseName: 'MY MYDIN',
          address: 'Kuala Lumpur',
          state: 'W.P. Kuala Lumpur',
          district: 'Kuala Lumpur',
          price: 0.69,
          recordDate: '2026-08-01',
        ),
      ],
    ),
  };

  @override
  Future<Item> getItem(int itemCode) async => _items[itemCode]!;
}
