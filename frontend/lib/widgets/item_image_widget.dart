import 'package:flutter/material.dart';

import '../services/item_image_resolver.dart';
import 'jimatmy_ui.dart';

class ItemImage extends StatefulWidget {
  const ItemImage({
    required this.itemCode,
    required this.itemName,
    required this.category,
    this.group = '',
    this.width = 78,
    this.height = 78,
    this.fit = BoxFit.contain,
    this.borderRadius = 16,
    this.resolver,
    super.key,
  });

  final int itemCode;
  final String itemName;
  final String category;
  final String group;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final ItemImageResolver? resolver;

  @override
  State<ItemImage> createState() => _ItemImageState();
}

class _ItemImageState extends State<ItemImage> {
  late Future<String?> _assetPath;

  ItemImageResolver get _resolver =>
      widget.resolver ?? ItemImageResolver.shared;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ItemImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCode != widget.itemCode ||
        oldWidget.itemName != widget.itemName ||
        oldWidget.resolver != widget.resolver) {
      _resolve();
    }
  }

  void _resolve() {
    _assetPath = _resolver.resolve(
      itemCode: widget.itemCode,
      itemName: widget.itemName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _ItemImageFallback(
      category: widget.category,
      group: widget.group,
    );
    return Semantics(
      label: '${widget.itemName} product image',
      image: true,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: JimatMyColors.mint,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: FutureBuilder<String?>(
          future: _assetPath,
          builder: (context, snapshot) {
            final path = snapshot.data;
            if (path == null) return fallback;
            return Image.asset(
              path,
              key: ValueKey('item-image-$path'),
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => fallback,
            );
          },
        ),
      ),
    );
  }
}

class _ItemImageFallback extends StatelessWidget {
  const _ItemImageFallback({required this.category, required this.group});

  final String category;
  final String group;

  @override
  Widget build(BuildContext context) {
    final categoryValue = category.trim().toUpperCase();
    final groupValue = group.trim().toUpperCase();
    final icon = switch (categoryValue) {
      'AYAM' => Icons.set_meal_rounded,
      'DAGING' => Icons.set_meal_rounded,
      'TELUR' => Icons.egg_alt_rounded,
      'SAYUR-SAYURAN' => Icons.eco_rounded,
      'BUAH-BUAHAN' => Icons.apple_rounded,
      _ when groupValue == 'MINUMAN' => Icons.local_drink_rounded,
      _ when groupValue == 'SUSU DAN BARANGAN BAYI' =>
        Icons.child_friendly_rounded,
      _ when groupValue == 'PRODUK KEBERSIHAN' =>
        Icons.cleaning_services_rounded,
      _ => Icons.shopping_basket_outlined,
    };
    return Center(child: Icon(icon, color: JimatMyColors.green, size: 34));
  }
}
