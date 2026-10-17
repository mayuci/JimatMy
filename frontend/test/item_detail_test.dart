import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/auth_user.dart';
import 'package:jimatmy/models/latest_price.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/models/price_trend.dart';
import 'package:jimatmy/models/user_features.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/providers/profile_provider.dart';
import 'package:jimatmy/screens/item_detail_screen.dart';
import 'package:jimatmy/screens/price_trend_screen.dart';
import 'package:jimatmy/screens/store_detail_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/services/item_image_resolver.dart';
import 'package:jimatmy/widgets/item_image_widget.dart';
import 'package:provider/provider.dart';

void main() {
  test('latest-price JSON safely parses a stable premise code', () {
    final valid = LatestPrice.fromJson(_priceJson(premiseCode: 22063));
    final missing = LatestPrice.fromJson(_priceJson());
    final blank = LatestPrice.fromJson(_priceJson(premiseCode: '  '));

    expect(valid.premiseCode, 22063);
    expect(missing.premiseCode, isNull);
    expect(blank.premiseCode, isNull);
  });

  testWidgets('no-prices item uses a constraint-safe sliver state', (
    tester,
  ) async {
    final api = _FakeItemApi(
      const Item(
        itemCode: 999,
        itemName: '100 PLUS',
        unit: '1 BOTOL',
        itemGroup: 'MINUMAN',
        itemCategory: 'MINUMAN BERKARBONAT',
      ),
    );

    await tester.pumpWidget(_testApp(api));
    await tester.pumpAndSettle();
    expect(find.text('100 PLUS'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('item-detail-scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.text('No prices yet'), findsOneWidget);
    expect(find.byTooltip('Add to favourites'), findsOneWidget);
    expect(find.byType(SliverFillRemaining), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item detail preserves loading and retryable error states', (
    tester,
  ) async {
    final pending = Completer<Item>();
    final api = _FakeItemApi.future(pending.future);
    await tester.pumpWidget(_testApp(api));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(ApiException('Test item error'));
    await tester.pumpAndSettle();
    expect(find.text('Details unavailable'), findsOneWidget);
    expect(find.text('Test item error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item detail premise opens Store Detail by code', (tester) async {
    final api = _FakeItemApi(_itemWithPrice(22063));
    await tester.pumpWidget(_testApp(api));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('item-detail-scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    final priceCard = find.ancestor(
      of: find.text('PASAR PUDU'),
      matching: find.byType(InkWell),
    );
    await tester.tap(priceCard);
    await tester.pumpAndSettle();

    final store = tester.widget<StoreDetailScreen>(
      find.byType(StoreDetailScreen),
    );
    expect(store.requestedPremiseCode, 22063);
    expect(api.requestedPremiseCodes, [22063]);
  });

  testWidgets('priced item calculates summary from real loaded prices', (
    tester,
  ) async {
    final api = _FakeItemApi(_itemWithPrice(22063));
    await tester.pumpWidget(_testApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Daily price'), findsOneWidget);
    expect(find.text('RM 8.00'), findsWidgets);
    expect(find.text('Premises'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item detail uses the shared featured item image', (
    tester,
  ) async {
    final api = _FakeItemApi(_chickenItem());
    final resolver = _featuredResolver();
    await tester.pumpWidget(
      _testApp(api, itemCode: 1, imageResolver: resolver),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<ItemImage>(find.byType(ItemImage));
    expect(image.itemCode, 1);
    expect(image.itemName, 'AYAM BERSIH - STANDARD');
    expect(image.category, 'AYAM');
    expect(image.width, 180);
    expect(image.height, 180);
    expect(
      find.byKey(
        const ValueKey('item-image-assets/images/featured/ayam_bersih.webp'),
      ),
      findsOneWidget,
    );
    expect(api.itemCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item detail passes loaded identity to Price Trend', (
    tester,
  ) async {
    final api = _FakeItemApi(_chickenItem());
    final resolver = _featuredResolver();
    await tester.pumpWidget(
      _testApp(api, itemCode: 1, imageResolver: resolver),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Price Trend'));
    await tester.pumpAndSettle();

    final screen = tester.widget<PriceTrendScreen>(
      find.byType(PriceTrendScreen),
    );
    expect(screen.itemCode, 1);
    expect(screen.itemName, 'AYAM BERSIH - STANDARD');
    expect(screen.unit, '1kg');
    expect(screen.category, 'AYAM');
    expect(screen.group, 'BARANGAN SEGAR');
    expect(screen.imageResolver, same(resolver));
    expect(api.itemCalls, 1);
    expect(api.trendCalls, 1);
  });

  testWidgets('missing premise code stays readable and safe at 360px', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeItemApi(_itemWithPrice(null));
    await tester.pumpWidget(_testApp(api));
    await tester.pumpAndSettle();

    expect(find.text('PASAR PUDU'), findsOneWidget);
    await tester.ensureVisible(find.text('PASAR PUDU'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PASAR PUDU'));
    await tester.pump();
    expect(find.byType(StoreDetailScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'authenticated detail records one view and updates favourite count',
    (tester) async {
      final api = _FakeItemApi(_chickenItem())..setAuthToken('test-token');
      final auth = AuthProvider(api)
        ..isRestoring = false
        ..user = AuthUser(
          userId: '11111111-1111-4111-8111-111111111111',
          name: 'Aina',
          email: 'aina@example.com',
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 31),
        );
      final profile = ProfileProvider(api)
        ..summary = const ProfileSummary(
          favoriteItemCount: 0,
          historyCount: 0,
          shoppingListCount: 0,
        );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: api),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: profile),
          ],
          child: const MaterialApp(home: ItemDetailScreen(itemCode: 1)),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.recordedViews, [1]);
      expect(profile.summary?.historyCount, 1);
      auth.notifyListeners();
      await tester.pump();
      expect(api.recordedViews, [1]);

      await tester.tap(find.byTooltip('Add to favourites'));
      await tester.pumpAndSettle();
      expect(profile.summary?.favoriteItemCount, 1);
      expect(profile.isFavorite(1), isTrue);
    },
  );
}

Map<String, dynamic> _priceJson({Object? premiseCode}) {
  final json = <String, dynamic>{
    'premiseName': 'PASAR PUDU',
    'address': 'JALAN PASAR, KUALA LUMPUR',
    'state': 'W.P. Kuala Lumpur',
    'district': 'Kuala Lumpur',
    'price': 8.0,
    'recordDate': '2026-07-31',
  };
  if (premiseCode != null) json['premiseCode'] = premiseCode;
  return json;
}

Item _itemWithPrice(int? premiseCode) => Item(
  itemCode: 999,
  itemName: 'TEST GROCERY',
  unit: '1kg',
  itemGroup: 'BARANGAN SEGAR',
  itemCategory: 'TEST',
  latestPrices: [
    LatestPrice(
      premiseCode: premiseCode,
      premiseName: 'PASAR PUDU',
      address: 'JALAN PASAR, KUALA LUMPUR',
      state: 'W.P. Kuala Lumpur',
      district: 'Kuala Lumpur',
      price: 8,
      recordDate: '2026-07-31',
    ),
  ],
);

Item _chickenItem() => const Item(
  itemCode: 1,
  itemName: 'AYAM BERSIH - STANDARD',
  unit: '1kg',
  itemGroup: 'BARANGAN SEGAR',
  itemCategory: 'AYAM',
);

ItemImageResolver _featuredResolver() => ItemImageResolver.fromAssetPaths(
  const ['${featuredItemImageDirectory}ayam_bersih.webp'],
);

Widget _testApp(
  ApiService api, {
  int itemCode = 999,
  ItemImageResolver? imageResolver,
}) => MultiProvider(
  providers: [
    Provider<ApiService>.value(value: api),
    ChangeNotifierProvider(create: (_) => AuthProvider(api)),
  ],
  child: MaterialApp(
    home: ItemDetailScreen(itemCode: itemCode, imageResolver: imageResolver),
  ),
);

class _FakeItemApi extends ApiService {
  _FakeItemApi(Item item) : response = Future.value(item);
  _FakeItemApi.future(this.response);

  final Future<Item> response;
  final List<int> requestedPremiseCodes = [];
  int itemCalls = 0;
  int trendCalls = 0;
  final List<int> recordedViews = [];

  @override
  Future<Item> getItem(int itemCode) {
    itemCalls += 1;
    return response;
  }

  @override
  Future<PriceTrend> getPriceTrend(
    int itemCode, {
    DateTime? from,
    DateTime? to,
  }) async {
    trendCalls += 1;
    return PriceTrend(
      item: await response,
      points: [
        PriceTrendPoint(
          recordDate: DateTime(2026, 7, 1),
          averagePrice: 9,
          minimumPrice: 8,
          maximumPrice: 10,
        ),
        PriceTrendPoint(
          recordDate: DateTime(2026, 7, 31),
          averagePrice: 9.5,
          minimumPrice: 8.5,
          maximumPrice: 11,
        ),
      ],
    );
  }

  @override
  Future<Premise> getPremise(int premiseCode) async {
    requestedPremiseCodes.add(premiseCode);
    return Premise(
      premiseCode: premiseCode,
      premiseName: 'PASAR PUDU',
      address: 'JALAN PASAR, KUALA LUMPUR',
      postcode: '55100',
      premiseType: 'Pasar',
      district: 'Kuala Lumpur',
      state: 'W.P. Kuala Lumpur',
      latitude: null,
      longitude: null,
    );
  }

  @override
  Future<bool> getFavoriteStatus(int itemCode) async => false;

  @override
  Future<bool> addFavoriteItem(int itemCode) async => true;

  @override
  Future<SearchHistoryEntry> recordItemView(int itemCode) async {
    recordedViews.add(itemCode);
    return SearchHistoryEntry(
      historyId: 'view-$itemCode',
      itemCode: itemCode,
      itemName: 'AYAM BERSIH - STANDARD',
      unit: '1kg',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'AYAM',
      lastViewedAt: DateTime(2026, 8, 31),
      wasCreated: true,
    );
  }
}
