String normalizeItemImageKey(String itemName) {
  var value = itemName.trim();
  value = value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  value = value.toLowerCase().replaceAll('&', ' and ');
  value = value.replaceAllMapped(
    RegExp(r'(\d(?:\.\d+)?)\s*(kg|g|ml|l)\b'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  value = value.replaceAll(RegExp('_+'), '_');
  return value.replaceAll(RegExp(r'^_+|_+$'), '');
}

String normalizeItemImageFilename(String filename) {
  final name = filename.split('/').last.split('\\').last;
  final withoutExtension = name.replaceFirst(
    RegExp(r'\.(?:webp|png|jpe?g)$', caseSensitive: false),
    '',
  );
  return normalizeItemImageKey(withoutExtension);
}

String itemImageFilename(String itemName, {String extension = 'webp'}) {
  final normalizedExtension = extension.toLowerCase().replaceFirst('.', '');
  return '${normalizeItemImageKey(itemName)}.$normalizedExtension';
}
