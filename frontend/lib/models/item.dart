import 'latest_price.dart';
import 'price_reliability.dart';

class Item {
  const Item({
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.itemGroup,
    required this.itemCategory,
    this.latestPrices = const [],
    this.lowestPrice,
    this.premiseCount = 0,
    this.reliability = PriceReliability.unavailable,
  });

  final int itemCode;
  final String itemName;
  final String unit;
  final String itemGroup;
  final String itemCategory;
  final List<LatestPrice> latestPrices;
  final double? lowestPrice;
  final int premiseCount;
  final PriceReliability reliability;

  factory Item.fromJson(Map<String, dynamic> json) {
    final prices = json['latestPrices'] as List<dynamic>? ?? const [];
    return Item(
      itemCode: json['itemCode'] as int,
      itemName: json['itemName'] as String,
      unit: json['unit'] as String,
      itemGroup: json['itemGroup'] as String,
      itemCategory: json['itemCategory'] as String,
      latestPrices: prices
          .map((value) => LatestPrice.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble(),
      premiseCount: (json['premiseCount'] as num?)?.toInt() ?? 0,
      reliability: PriceReliability.fromJson(
        json['reliability'] as Map<String, dynamic>?,
      ),
    );
  }
}

class ItemPage {
  const ItemPage({required this.items, required this.total});
  final List<Item> items;
  final int total;
}
