import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/services/item_image_resolver.dart';
import 'package:jimatmy/utils/item_image_key.dart';
import 'package:jimatmy/widgets/item_image_widget.dart';

void main() {
  test('normalizes official item names deterministically', () {
    expect(normalizeItemImageKey(' AYAM BERSIH - SUPER '), 'ayam_bersih_super');
    expect(normalizeItemImageKey('100 PLUS (ORIGINAL)'), '100_plus_original');
    expect(
      normalizeItemImageKey('Milk & Eggs --- Value!!'),
      'milk_and_eggs_value',
    );
    expect(normalizeItemImageFilename('DadaAyam.jpg'), 'dada_ayam');
    expect(normalizeItemImageFilename('100Plus-1.5L.jpg'), '100_plus_1_5_l');
    expect(
      normalizeItemImageKey('100 Plus 1.5 L'),
      normalizeItemImageFilename('100Plus-1.5L.jpg'),
    );
    expect(
      normalizeItemImageKey('DUMEX DUGRO 3 850 g'),
      normalizeItemImageKey('DUMEX DUGRO 3 850g'),
    );
    expect(itemImageFilename('AYAM BERSIH - SUPER'), 'ayam_bersih_super.webp');
  });

  test('disambiguated item-code asset wins over the plain exact asset', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${featuredItemImageDirectory}ayam_bersih_standard.webp',
      '${featuredItemImageDirectory}ayam_bersih_standard__1.png',
    ]);
    expect(
      index.resolve(itemCode: 1, itemName: 'AYAM BERSIH - STANDARD'),
      '${featuredItemImageDirectory}ayam_bersih_standard__1.png',
    );
  });

  test('exact match wins over a generic fallback', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${featuredItemImageDirectory}ayam_bersih.webp',
      '${featuredItemImageDirectory}ayam_bersih_standard.jpg',
    ]);
    expect(
      index.resolve(itemCode: 1, itemName: 'AYAM BERSIH - STANDARD'),
      '${featuredItemImageDirectory}ayam_bersih_standard.jpg',
    );
  });

  test('product exact match wins over a featured image', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${productItemImageDirectory}AnggurHijauBerbiji.jpg',
      '${featuredItemImageDirectory}anggur_hijau_berbiji.webp',
    ]);
    expect(
      index.resolve(itemCode: 26, itemName: 'ANGGUR HIJAU BERBIJI'),
      '${productItemImageDirectory}AnggurHijauBerbiji.jpg',
    );
  });

  test('reviewed item-code alias resolves a known abbreviated filename', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${productItemImageDirectory}DadaAyam.jpg',
    ]);
    final match = index.match(
      itemCode: 1551,
      itemName: 'DADA AYAM (CHICKEN KEEL) (1KG)',
    );
    expect(match?.path, '${productItemImageDirectory}DadaAyam.jpg');
    expect(match?.source, ItemImageSource.alias);
  });

  test('weekly basket products use the reviewed local JPG assets', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      'assets/images/products/susu segar dutch lady.jpg',
      'assets/images/products/minyak masak packet.jpg',
      'assets/images/products/beras cap jasmine.jpg',
      'assets/images/products/gula putih bertapis halus.jpg',
    ]);

    expect(
      index.resolve(itemCode: 224, itemName: 'SUSU SEGAR DUTCH LADY'),
      'assets/images/products/susu segar dutch lady.jpg',
    );
    expect(
      index.resolve(
        itemCode: 918,
        itemName: 'MINYAK MASAK PAKET (PELBAGAI JENAMA)',
      ),
      'assets/images/products/minyak masak packet.jpg',
    );
    expect(
      index.resolve(itemCode: 1582, itemName: 'BERAS CAP JASMINE (SST5%)'),
      'assets/images/products/beras cap jasmine.jpg',
    );
    expect(
      index.resolve(
        itemCode: 1590,
        itemName: 'GULA PUTIH BERTAPIS HALUS (PELBAGAI JENAMA)',
      ),
      'assets/images/products/gula putih bertapis halus.jpg',
    );
  });

  test('duplicate normalized filenames remain unassigned', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${productItemImageDirectory}DadaAyam.jpg',
      '${productItemImageDirectory}Dada_Ayam.png',
    ]);
    expect(index.resolve(itemCode: 9999, itemName: 'DADA AYAM'), isNull);
    expect(index.duplicateNormalizedProductFilenames, contains('dada_ayam'));
  });

  test('supports WebP, PNG, JPG and JPEG extensions', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${featuredItemImageDirectory}item_webp.webp',
      '${featuredItemImageDirectory}item_png.png',
      '${featuredItemImageDirectory}item_jpg.jpg',
      '${featuredItemImageDirectory}item_jpeg.jpeg',
      '${featuredItemImageDirectory}ignored.gif',
    ]);
    expect(
      index.resolve(itemCode: 1, itemName: 'ITEM WEBP'),
      endsWith('.webp'),
    );
    expect(index.resolve(itemCode: 2, itemName: 'ITEM PNG'), endsWith('.png'));
    expect(index.resolve(itemCode: 3, itemName: 'ITEM JPG'), endsWith('.jpg'));
    expect(
      index.resolve(itemCode: 4, itemName: 'ITEM JPEG'),
      endsWith('.jpeg'),
    );
    expect(index.resolve(itemCode: 5, itemName: 'IGNORED'), isNull);
  });

  test('uses the longest complete-token generic prefix', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${featuredItemImageDirectory}ayam_bersih.webp',
      '${featuredItemImageDirectory}ayam_bersih_standard.webp',
    ]);
    expect(
      index.resolve(itemCode: 8, itemName: 'AYAM BERSIH STANDARD BESAR'),
      '${featuredItemImageDirectory}ayam_bersih_standard.webp',
    );
  });

  test('rejects one-token and arbitrary substring matching', () {
    final index = ItemImageIndex.fromAssetPaths(const [
      '${featuredItemImageDirectory}ayam.webp',
      '${featuredItemImageDirectory}bersih_standard.webp',
    ]);
    expect(
      index.resolve(itemCode: 1, itemName: 'AYAM BERSIH STANDARD'),
      isNull,
    );
  });

  test('asset manifest loader is indexed once per resolver', () async {
    var loadCount = 0;
    final resolver = ItemImageResolver(
      assetLoader: () async {
        loadCount++;
        return const ['${featuredItemImageDirectory}ayam_bersih.webp'];
      },
    );
    await resolver.resolve(itemCode: 1, itemName: 'AYAM BERSIH STANDARD');
    await resolver.resolve(itemCode: 2, itemName: 'AYAM BERSIH SUPER');
    expect(loadCount, 1);
  });

  testWidgets('missing and broken assets use a safe category fallback', (
    tester,
  ) async {
    final missingResolver = ItemImageResolver.fromAssetPaths(const []);
    await tester.pumpWidget(
      MaterialApp(
        home: ItemImage(
          itemCode: 4,
          itemName: 'UNKNOWN VEGETABLE',
          category: 'SAYUR-SAYURAN',
          resolver: missingResolver,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);

    final brokenResolver = ItemImageResolver.fromAssetPaths(const [
      '${featuredItemImageDirectory}broken_product.webp',
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ItemImage(
          itemCode: 5,
          itemName: 'BROKEN PRODUCT',
          category: '',
          resolver: brokenResolver,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('widget re-resolves when item identity changes', (tester) async {
    final resolver = ItemImageResolver.fromAssetPaths(const [
      '${featuredItemImageDirectory}ayam_bersih.webp',
      '${featuredItemImageDirectory}kangkung.webp',
    ]);
    Widget app(int code, String name) => MaterialApp(
      home: ItemImage(
        itemCode: code,
        itemName: name,
        category: 'SAYUR-SAYURAN',
        resolver: resolver,
      ),
    );

    await tester.pumpWidget(app(1, 'AYAM BERSIH STANDARD'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('item-image-assets/images/featured/ayam_bersih.webp'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(app(1559, 'KANGKUNG'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('item-image-assets/images/featured/kangkung.webp'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('every bundled product image exists and can be loaded', (
    tester,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final productAssets = manifest
        .listAssets()
        .where((path) => path.startsWith(productItemImageDirectory))
        .where(
          (path) => supportedItemImageExtensions.contains(
            path.split('.').last.toLowerCase(),
          ),
        )
        .toList(growable: false);

    expect(productAssets, isNotEmpty);
    for (final path in productAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}
