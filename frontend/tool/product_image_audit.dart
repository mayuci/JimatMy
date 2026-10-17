import 'dart:convert';
import 'dart:io';

import 'package:jimatmy/utils/item_image_catalog.dart';

const _defaultApiBase = 'http://localhost:3000/api';
const _defaultOutput = 'docs/product_image_audit.txt';

class _CatalogItem {
  const _CatalogItem({required this.code, required this.name});

  final int code;
  final String name;
}

Future<void> main(List<String> arguments) async {
  final apiBase = _argument(arguments, '--api-base') ?? _defaultApiBase;
  final outputPath = _argument(arguments, '--output') ?? _defaultOutput;
  final productFiles = _assetFiles(Directory('assets/images/products'));
  final featuredFiles = _assetFiles(Directory('assets/images/featured'));
  final items = await _loadGroceryItems(apiBase);
  final index = ItemImageIndex.fromAssetPaths([
    ...productFiles,
    ...featuredFiles,
  ]);

  final assignments = <String, List<_CatalogItem>>{};
  final missingItems = <_CatalogItem>[];
  for (final item in items) {
    final match = index.match(itemCode: item.code, itemName: item.name);
    if (match == null) {
      missingItems.add(item);
    } else {
      assignments.putIfAbsent(match.path, () => []).add(item);
    }
  }

  final ambiguousPaths = reviewedAmbiguousProductImages.keys.toSet();
  final matchedProductFiles = productFiles
      .where((path) => assignments[path]?.isNotEmpty == true)
      .toList(growable: false);
  final unmatchedProductFiles = productFiles
      .where(
        (path) =>
            !ambiguousPaths.contains(path) &&
            assignments[path]?.isNotEmpty != true,
      )
      .toList(growable: false);
  final multipleAssignments = assignments.entries
      .where((entry) => entry.value.length > 1)
      .toList(growable: false);

  final buffer = StringBuffer()
    ..writeln('JimatMY product image audit')
    ..writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln('Catalog scope: grocery items returned by GET /api/items')
    ..writeln()
    ..writeln('SUMMARY')
    ..writeln('Product image files: ${productFiles.length}')
    ..writeln('Matched product images: ${matchedProductFiles.length}')
    ..writeln('Unmatched product images: ${unmatchedProductFiles.length}')
    ..writeln('Ambiguous product images: ${ambiguousPaths.length}')
    ..writeln('Grocery catalog items: ${items.length}')
    ..writeln('Items with an image: ${items.length - missingItems.length}')
    ..writeln('Items still missing images: ${missingItems.length}')
    ..writeln()
    ..writeln('MATCHED PRODUCT IMAGES');
  for (final path in matchedProductFiles) {
    buffer.writeln(
      '${_relativeName(path)} -> ${_items(assignments[path] ?? const [])}',
    );
  }

  buffer
    ..writeln()
    ..writeln('UNMATCHED PRODUCT IMAGES');
  if (unmatchedProductFiles.isEmpty) buffer.writeln('None');
  for (final path in unmatchedProductFiles) {
    buffer.writeln(_relativeName(path));
  }

  buffer
    ..writeln()
    ..writeln('AMBIGUOUS PRODUCT IMAGES (not assigned)');
  for (final entry in reviewedAmbiguousProductImages.entries) {
    final candidates = items
        .where((item) => entry.value.contains(item.code))
        .toList(growable: false);
    buffer.writeln('${_relativeName(entry.key)} -> ${_items(candidates)}');
  }

  buffer
    ..writeln()
    ..writeln('REVIEWED ALIASES');
  for (final entry in reviewedItemImageAliases.entries) {
    final item = items.where((item) => item.code == entry.key).firstOrNull;
    buffer.writeln(
      '${entry.key} ${item?.name ?? '(not in grocery response)'} -> '
      '${_relativeName(entry.value)}',
    );
  }

  buffer
    ..writeln()
    ..writeln('DUPLICATE NORMALIZED FILENAMES');
  if (index.duplicateNormalizedProductFilenames.isEmpty) {
    buffer.writeln('None');
  }
  for (final entry in index.duplicateNormalizedProductFilenames.entries) {
    buffer.writeln('${entry.key} -> ${entry.value.join(', ')}');
  }

  buffer
    ..writeln()
    ..writeln('IMAGES ASSIGNED TO MULTIPLE ITEMS');
  if (multipleAssignments.isEmpty) buffer.writeln('None');
  for (final entry in multipleAssignments) {
    buffer.writeln('${_relativeName(entry.key)} -> ${_items(entry.value)}');
  }

  buffer
    ..writeln()
    ..writeln('ITEMS STILL MISSING IMAGES');
  for (final item in missingItems) {
    buffer.writeln('${item.code}\t${item.name}');
  }

  final output = File(outputPath);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(buffer.toString());
  stdout.write(buffer.toString().split('ITEMS STILL MISSING IMAGES').first);
  stdout.writeln('Full report: ${output.path}');
}

String? _argument(List<String> arguments, String name) {
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument.startsWith('$name=')) {
      return argument.substring(name.length + 1);
    }
    if (argument == name && index + 1 < arguments.length) {
      return arguments[index + 1];
    }
  }
  return null;
}

List<String> _assetFiles(Directory directory) {
  if (!directory.existsSync()) return const [];
  final prefix = directory.path.replaceAll('\\', '/');
  return directory
      .listSync(followLinks: false)
      .whereType<File>()
      .map((file) => '$prefix/${file.uri.pathSegments.last}')
      .where(
        (path) => supportedItemImageExtensions.contains(
          path.split('.').last.toLowerCase(),
        ),
      )
      .toList(growable: false)
    ..sort();
}

Future<List<_CatalogItem>> _loadGroceryItems(String apiBase) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  final items = <_CatalogItem>[];
  try {
    var offset = 0;
    while (true) {
      final uri = Uri.parse('$apiBase/items').replace(
        queryParameters: {
          'limit': '100',
          'offset': '$offset',
          'includePreparedFood': 'false',
        },
      );
      final response = await (await client.getUrl(uri)).close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Items API returned HTTP ${response.statusCode}.');
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      items.addAll(
        data.map((value) {
          final item = value as Map<String, dynamic>;
          return _CatalogItem(
            code: (item['itemCode'] as num).toInt(),
            name: item['itemName'] as String,
          );
        }),
      );
      final meta = json['meta'] as Map<String, dynamic>?;
      final total = (meta?['total'] as num?)?.toInt() ?? items.length;
      if (items.length >= total || data.isEmpty) break;
      offset += data.length;
    }
    return items;
  } finally {
    client.close(force: true);
  }
}

String _relativeName(String path) =>
    path.replaceFirst(productItemImageDirectory, '');

String _items(List<_CatalogItem> items) =>
    items.map((item) => '${item.code} ${item.name}').join(' | ');

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
