import 'item_image_key.dart';

const productItemImageDirectory = 'assets/images/products/';
const featuredItemImageDirectory = 'assets/images/featured/';
const supportedItemImageExtensions = {'webp', 'png', 'jpg', 'jpeg'};

/// Reviewed aliases for filenames that intentionally abbreviate or misspell
/// one unambiguous official PriceCatcher item.
const reviewedItemImageAliases = <int, String>{
  224: '${productItemImageDirectory}susu segar dutch lady.jpg',
  25: '${productItemImageDirectory}nenas biasa.jpg',
  119: '${productItemImageDirectory}telur ayam gred b 10 biji.jpg',
  120: '${productItemImageDirectory}telur ayam gred c 10 biji.jpg',
  221: '${productItemImageDirectory}drinho soya.jpg',
  228: '${productItemImageDirectory}coca cola 1.5.jpg',
  235: '${productItemImageDirectory}jus oren peel fresh.jpg',
  300: '${productItemImageDirectory}lactogen 2 rumusan susulan.jpg',
  716: '${productItemImageDirectory}cili api hijau.jpg',
  910: '${productItemImageDirectory}kordial F&N.jpg',
  918: '${productItemImageDirectory}minyak masak packet.jpg',
  1110: '${productItemImageDirectory}telur ayam gred b 30 biji.jpg',
  1111: '${productItemImageDirectory}telur ayam gred c 30 biji.jpg',
  1355: '${productItemImageDirectory}100Plus-1.5L.jpg',
  1379: '${productItemImageDirectory}daging babi (belly).jpg',
  1380: '${productItemImageDirectory}daging babi (daging & lemak).jpg',
  1400: '${productItemImageDirectory}bawang perai import.jpg',
  1441: '${productItemImageDirectory}bawang bersar import china.jpg',
  1515: '${productItemImageDirectory}heinz farley rucks ori.jpg',
  1524: '${productItemImageDirectory}berus gigi colgate zigzag soft.jpg',
  1525: '${productItemImageDirectory}berus gigi oral b.jpg',
  1550: '${productItemImageDirectory}PahaAyam.jpg',
  1551: '${productItemImageDirectory}DadaAyam.jpg',
  1582: '${productItemImageDirectory}beras cap jasmine.jpg',
  1590: '${productItemImageDirectory}gula putih bertapis halus.jpg',
  1804: '${productItemImageDirectory}KepakAyam.jpg',
  1876: '${productItemImageDirectory}pelembut pakaian downy premium.jpg',
  1904: '${productItemImageDirectory}dumex dugro 3 850g.jpg',
  1987: '${productItemImageDirectory}deodoran nivea black and white.jpg',
  1990: '${productItemImageDirectory}deodoran rexona powder dry brightning.jpg',
  2001: '${productItemImageDirectory}dumex dugro 2 850g.jpg',
  2010: '${productItemImageDirectory}dutch lady 456.jpg',
  2019: '${productItemImageDirectory}nesvafe 3 in 1 original aromatic.jpg',
};

const reviewedAmbiguousProductImages = <String, List<int>>{
  '${productItemImageDirectory}dutch lady 123.jpg': [1874, 2009],
  '${productItemImageDirectory}enfagrow A+ Mind Pro Kotak.jpg': [303, 2014],
};

enum ItemImageSource { productCode, productExact, alias, featured }

class ItemImageMatch {
  const ItemImageMatch({required this.path, required this.source});

  final String path;
  final ItemImageSource source;
}

class ItemImageIndex {
  ItemImageIndex._({
    required this._productAssets,
    required this._productCodeAssets,
    required this._featuredAssets,
    required this._featuredCodeAssets,
    required this._assetPaths,
  });

  factory ItemImageIndex.fromAssetPaths(Iterable<String> assetPaths) {
    final paths = assetPaths.where(_isSupportedAsset).toList(growable: false)
      ..sort(_compareAssetPaths);
    final productAssets = <String, List<String>>{};
    final productCodeAssets = <String, List<String>>{};
    final featuredAssets = <String, List<String>>{};
    final featuredCodeAssets = <String, List<String>>{};
    for (final path in paths) {
      final isProduct = path.startsWith(productItemImageDirectory);
      final codeKey = _codeSpecificKey(path);
      final target = codeKey == null
          ? (isProduct ? productAssets : featuredAssets)
          : (isProduct ? productCodeAssets : featuredCodeAssets);
      final key = codeKey ?? normalizeItemImageFilename(path);
      if (key.isNotEmpty) target.putIfAbsent(key, () => []).add(path);
    }
    return ItemImageIndex._(
      productAssets: _freeze(productAssets),
      productCodeAssets: _freeze(productCodeAssets),
      featuredAssets: _freeze(featuredAssets),
      featuredCodeAssets: _freeze(featuredCodeAssets),
      assetPaths: Set.unmodifiable(paths),
    );
  }

  final Map<String, List<String>> _productAssets;
  final Map<String, List<String>> _productCodeAssets;
  final Map<String, List<String>> _featuredAssets;
  final Map<String, List<String>> _featuredCodeAssets;
  final Set<String> _assetPaths;

  Map<String, List<String>> get duplicateNormalizedProductFilenames =>
      Map.unmodifiable(
        Map.fromEntries(
          _productAssets.entries.where((entry) => entry.value.length > 1),
        ),
      );

  ItemImageMatch? match({required int itemCode, required String itemName}) {
    final itemKey = normalizeItemImageKey(itemName);
    if (itemKey.isEmpty) return null;

    final productCodeMatch = _single(
      _productCodeAssets['${itemKey}__$itemCode'],
    );
    if (productCodeMatch != null) {
      return ItemImageMatch(
        path: productCodeMatch,
        source: ItemImageSource.productCode,
      );
    }

    final exactProduct = _single(_productAssets[itemKey]);
    if (exactProduct != null) {
      return ItemImageMatch(
        path: exactProduct,
        source: ItemImageSource.productExact,
      );
    }

    final alias = reviewedItemImageAliases[itemCode];
    if (alias != null && _assetPaths.contains(alias)) {
      return ItemImageMatch(path: alias, source: ItemImageSource.alias);
    }

    final codeFeatured = _single(_featuredCodeAssets['${itemKey}__$itemCode']);
    if (codeFeatured != null) {
      return ItemImageMatch(
        path: codeFeatured,
        source: ItemImageSource.featured,
      );
    }

    final exactFeatured = _single(_featuredAssets[itemKey]);
    if (exactFeatured != null) {
      return ItemImageMatch(
        path: exactFeatured,
        source: ItemImageSource.featured,
      );
    }

    String? longestPrefix;
    for (final entry in _featuredAssets.entries) {
      if (entry.value.length != 1 || entry.key.contains('__')) continue;
      final tokenCount = entry.key
          .split('_')
          .where((token) => token.isNotEmpty)
          .length;
      if (tokenCount < 2 || !itemKey.startsWith('${entry.key}_')) continue;
      if (longestPrefix == null || entry.key.length > longestPrefix.length) {
        longestPrefix = entry.key;
      }
    }
    final featured = longestPrefix == null
        ? null
        : _single(_featuredAssets[longestPrefix]);
    return featured == null
        ? null
        : ItemImageMatch(path: featured, source: ItemImageSource.featured);
  }

  String? resolve({required int itemCode, required String itemName}) =>
      match(itemCode: itemCode, itemName: itemName)?.path;

  static bool _isSupportedAsset(String path) {
    final isImageDirectory =
        path.startsWith(productItemImageDirectory) ||
        path.startsWith(featuredItemImageDirectory);
    return isImageDirectory &&
        supportedItemImageExtensions.contains(_extension(path));
  }

  static Map<String, List<String>> _freeze(Map<String, List<String>> source) =>
      Map<String, List<String>>.unmodifiable(
        source.map(
          (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
        ),
      );

  static String? _single(List<String>? paths) =>
      paths?.length == 1 ? paths!.single : null;

  static String _extension(String path) => path.split('.').last.toLowerCase();

  static String? _codeSpecificKey(String path) {
    final filename = path.split('/').last;
    final extensionLength = _extension(filename).length + 1;
    final stem = filename.substring(0, filename.length - extensionLength);
    final match = RegExp(r'^(.*)__([0-9]+)$').firstMatch(stem);
    if (match == null) return null;
    final nameKey = normalizeItemImageKey(match.group(1) ?? '');
    return nameKey.isEmpty ? null : '${nameKey}__${match.group(2)}';
  }

  static int _compareAssetPaths(String first, String second) {
    final keyOrder = normalizeItemImageFilename(first)
        .compareTo(normalizeItemImageFilename(second));
    if (keyOrder != 0) return keyOrder;
    final extensionOrder = _extensionPriority(_extension(first))
        .compareTo(_extensionPriority(_extension(second)));
    return extensionOrder != 0 ? extensionOrder : first.compareTo(second);
  }

  static int _extensionPriority(String extension) => switch (extension) {
    'webp' => 0,
    'png' => 1,
    'jpg' => 2,
    'jpeg' => 3,
    _ => 4,
  };
}
