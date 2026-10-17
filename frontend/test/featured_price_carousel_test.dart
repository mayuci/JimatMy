import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/latest_price.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/screens/item_detail_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/widgets/featured_price_carousel_widget.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('featured slides format real prices and support navigation', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(720, 1600)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FeaturedApi();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ],
        child: MaterialApp(
          home: Scaffold(body: FeaturedPriceCarouselWidget(apiService: api)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.text('From RM 7.95'), findsOneWidget);
    expect(find.text('View prices'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsWidgets);

    await tester.tap(find.text('View prices'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  testWidgets('featured carousel has no overflow at narrow width', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(720, 1600)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _FeaturedApi();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: FeaturedPriceCarouselWidget(apiService: api),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FeaturedApi extends ApiService {
  @override
  Future<Item> getItem(int itemCode) async {
    if (itemCode == 1) {
      return const Item(
        itemCode: 1,
        itemName: 'AYAM BERSIH - STANDARD',
        unit: '1 kg',
        itemGroup: 'BARANGAN SEGAR',
        itemCategory: 'AYAM',
        latestPrices: [
          LatestPrice(
            premiseCode: 1,
            premiseName: 'Test Fresh Mart',
            address: 'Address',
            state: 'Selangor',
            district: 'Petaling',
            price: 7.95,
            recordDate: '2026-08-01',
          ),
        ],
      );
    }
    return Item(
      itemCode: itemCode,
      itemName: 'Featured $itemCode',
      unit: '1 unit',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'SAYUR-SAYURAN',
    );
  }
}
