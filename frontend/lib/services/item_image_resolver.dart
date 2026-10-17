import 'package:flutter/services.dart';

import '../utils/item_image_catalog.dart';
export '../utils/item_image_catalog.dart';

typedef ItemAssetLoader = Future<Iterable<String>> Function();

class ItemImageResolver {
  ItemImageResolver({ItemAssetLoader? assetLoader})
    : _assetLoader = assetLoader ?? _loadBundledAssets;

  factory ItemImageResolver.fromAssetPaths(Iterable<String> assetPaths) =>
      ItemImageResolver(assetLoader: () async => assetPaths);

  static final shared = ItemImageResolver();

  final ItemAssetLoader _assetLoader;
  Future<ItemImageIndex>? _indexFuture;

  Future<String?> resolve({
    required int itemCode,
    required String itemName,
  }) async {
    final index = await (_indexFuture ??= _loadIndex());
    return index.resolve(itemCode: itemCode, itemName: itemName);
  }

  Future<ItemImageIndex> _loadIndex() async =>
      ItemImageIndex.fromAssetPaths(await _assetLoader());

  static Future<Iterable<String>> _loadBundledAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets();
  }
}
