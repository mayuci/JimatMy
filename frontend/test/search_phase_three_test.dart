import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/providers/item_provider.dart';
import 'package:jimatmy/screens/item_detail_screen.dart';
import 'package:jimatmy/screens/search_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  test('item discovery model parses batched price summary fields', () {
    final item = Item.fromJson({
      'itemCode': 1,
      'itemName': 'AYAM BERSIH - STANDARD',
      'unit': '1 kg',
      'itemGroup': 'BARANGAN SEGAR',
      'itemCategory': 'AYAM',
      'lowestPrice': 8.99,
      'premiseCount': 12,
    });

    expect(item.lowestPrice, 8.99);
    expect(item.premiseCount, 12);
  });

  testWidgets('matching image and real price summary open the correct item', (
    tester,
  ) async {
    final api = _SearchApi();
    await _pumpSearch(tester, api);

    expect(
      find.byKey(
        const ValueKey('item-image-assets/images/featured/ayam_bersih.webp'),
      ),
      findsOneWidget,
    );
    expect(find.text('From RM 8.99'), findsOneWidget);
    expect(find.text('12 premises'), findsOneWidget);
    final callsBeforeImageSettled = api.calls.length;
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.calls.length, callsBeforeImageSettled);

    await tester.tap(find.byKey(const ValueKey('search-item-action-1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ItemDetailScreen>(find.byType(ItemDetailScreen)).itemCode,
      1,
    );
  });

  testWidgets('missing image and missing price use safe honest fallbacks', (
    tester,
  ) async {
    final api = _SearchApi();
    await _pumpSearch(tester, api);

    expect(find.byIcon(Icons.cleaning_services_rounded), findsOneWidget);
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.text('1 premise'), findsOneWidget);
    expect(find.textContaining('RM 0'), findsNothing);
  });

  testWidgets('debounce sends one request and clearing restores browsing', (
    tester,
  ) async {
    final api = _SearchApi();
    await _pumpSearch(tester, api);
    final initialCalls = api.calls.length;

    final search = find.byKey(const ValueKey('item-search-field'));
    await tester.enterText(search, 'a');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.enterText(search, 'ay');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.enterText(search, 'ayam');
    await tester.pump(const Duration(milliseconds: 460));

    expect(api.calls.length, initialCalls + 1);
    expect(api.calls.last.query, 'ayam');

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(api.calls.last.query, '');
    expect(api.calls.last.offset, 0);
    expect(find.text('Browse items'), findsOneWidget);
  });

  testWidgets('official category resets pagination and keeps current query', (
    tester,
  ) async {
    final api = _SearchApi();
    await _pumpSearch(tester, api);
    final provider = tester
        .element(find.byKey(const ValueKey('item-search-field')))
        .read<ItemProvider>();

    await provider.loadMore();
    expect(api.calls.last.offset, 2);

    await tester.enterText(
      find.byKey(const ValueKey('item-search-field')),
      'standard',
    );
    await tester.pump(const Duration(milliseconds: 460));
    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();

    expect(api.calls.last.category, 'chicken');
    expect(api.calls.last.query, 'standard');
    expect(api.calls.last.offset, 0);
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
  });

  testWidgets('pagination never duplicates an existing item code', (
    tester,
  ) async {
    final api = _SearchApi();
    await _pumpSearch(tester, api);
    final provider = tester
        .element(find.byKey(const ValueKey('item-search-field')))
        .read<ItemProvider>();

    await provider.loadMore();
    await tester.pump();
    expect(provider.items.map((item) => item.itemCode), [1, 9000, 42]);
  });

  testWidgets('available-only is the default and filters apply once', (
    tester,
  ) async {
    final api = _SearchApi();
    await _pumpSearch(tester, api);
    final callsBeforeSheet = api.calls.length;

    expect(api.calls.first.pricedOnly, isTrue);
    expect(find.text('Prices available'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-item-filters')));
    await tester.pumpAndSettle();
    expect(api.calls.length, callsBeforeSheet);
    expect(find.text('Has available prices'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.ensureVisible(find.text('Apply filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(api.calls.length, callsBeforeSheet + 1);
    expect(api.calls.last.pricedOnly, isFalse);
    expect(find.text('Prices available'), findsNothing);
  });

  testWidgets('320px layout with text scaling does not overflow', (
    tester,
  ) async {
    final api = _SearchApi();
    await _pumpSearch(tester, api, size: const Size(320, 568), textScale: 1.25);

    expect(find.text('Search items'), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSearch(
  WidgetTester tester,
  _SearchApi api, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SearchScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

class _ItemCall {
  const _ItemCall({
    required this.query,
    required this.category,
    required this.offset,
    required this.pricedOnly,
  });

  final String query;
  final String? category;
  final int offset;
  final bool pricedOnly;
}

class _SearchApi extends ApiService {
  final List<_ItemCall> calls = [];

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
    calls.add(
      _ItemCall(
        query: query,
        category: category,
        offset: offset,
        pricedOnly: pricedOnly,
      ),
    );
    if (category == 'chicken') {
      return const ItemPage(items: [_chicken], total: 1);
    }
    if (offset > 0) {
      return const ItemPage(items: [_chicken, _meat], total: 3);
    }
    return const ItemPage(items: [_chicken, _unknown], total: 3);
  }

  @override
  Future<Item> getItem(int itemCode) async => switch (itemCode) {
    42 => _meat,
    9000 => _unknown,
    _ => _chicken,
  };

  @override
  Future<List<PremiseFilterGroup>> getPremiseFilters() async => const [
    PremiseFilterGroup(state: 'Selangor', districts: ['Petaling']),
  ];
}

const _chicken = Item(
  itemCode: 1,
  itemName: 'AYAM BERSIH - STANDARD',
  unit: '1 kg',
  itemGroup: 'BARANGAN SEGAR',
  itemCategory: 'AYAM',
  lowestPrice: 8.99,
  premiseCount: 12,
);

const _unknown = Item(
  itemCode: 9000,
  itemName: 'UNMAPPED CLEANING PRODUCT',
  unit: '1 unit',
  itemGroup: 'PRODUK KEBERSIHAN',
  itemCategory: 'PENCUCI',
  premiseCount: 1,
);

const _meat = Item(
  itemCode: 42,
  itemName: 'DAGING LEMBU TEMPATAN',
  unit: '1 kg',
  itemGroup: 'BARANGAN SEGAR',
  itemCategory: 'DAGING',
  lowestPrice: 18.50,
  premiseCount: 4,
);
