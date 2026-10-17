import 'package:flutter/material.dart';

String groceryAssetFor(String name) {
  final value = name.toLowerCase();
  if (value.contains('ayam') || value.contains('chicken')) {
    return 'assets/images/chicken.png';
  }
  if (value.contains('telur') || value.contains('egg')) {
    return 'assets/images/eggs.png';
  }
  if (value.contains('beras') || value.contains('rice')) {
    return 'assets/images/rice.png';
  }
  if (value.contains('bawang') || value.contains('onion')) {
    return 'assets/images/onion.png';
  }
  if (value.contains('minyak') || value.contains('oil')) {
    return 'assets/images/oil.png';
  }
  return 'assets/images/basket.png';
}

class GroceryAsset extends StatelessWidget {
  const GroceryAsset({
    required this.name,
    this.itemCategory,
    this.itemGroup,
    this.size = 56,
    this.fit = BoxFit.cover,
    super.key,
  });
  final String name;
  final String? itemCategory;
  final String? itemGroup;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final hasMappedImage = _hasMappedImage(name);
    if (!hasMappedImage && itemCategory != null) {
      return _CategoryFallback(
        category: itemCategory!,
        group: itemGroup ?? '',
        size: size,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        groceryAssetFor(name),
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, _, _) => _CategoryFallback(
          category: itemCategory ?? '',
          group: itemGroup ?? '',
          size: size,
        ),
      ),
    );
  }
}

bool _hasMappedImage(String name) {
  final value = name.toLowerCase();
  return value.contains('ayam') ||
      value.contains('chicken') ||
      value.contains('telur') ||
      value.contains('egg') ||
      value.contains('beras') ||
      value.contains('rice') ||
      value.contains('bawang') ||
      value.contains('onion') ||
      value.contains('minyak') ||
      value.contains('oil');
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({
    required this.category,
    required this.group,
    required this.size,
  });

  final String category;
  final String group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = category.trim().toUpperCase();
    final groupValue = group.trim().toUpperCase();
    final icon = switch (value) {
      'SAYUR-SAYURAN' => Icons.eco_rounded,
      'BUAH-BUAHAN' => Icons.apple_rounded,
      'TELUR' => Icons.egg_alt_rounded,
      'DAGING' => Icons.set_meal_rounded,
      _ when groupValue == 'MINUMAN' => Icons.local_drink_rounded,
      _ when groupValue == 'SUSU DAN BARANGAN BAYI' =>
        Icons.child_friendly_rounded,
      _ when groupValue == 'PRODUK KEBERSIHAN' =>
        Icons.cleaning_services_rounded,
      _ => Icons.shopping_basket_outlined,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE5F5EA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: const Color(0xFF167D55)),
    );
  }
}
