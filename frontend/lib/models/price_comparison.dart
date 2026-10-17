import 'item.dart';
import 'latest_price.dart';

class CheapestOption {
  const CheapestOption({
    required this.premiseCode,
    required this.premiseName,
    required this.price,
    required this.recordDate,
  });

  final int? premiseCode;
  final String premiseName;
  final double price;
  final String recordDate;

  factory CheapestOption.fromJson(Map<String, dynamic> json) => CheapestOption(
    premiseCode: parsePremiseCode(json['premiseCode']),
    premiseName: json['premiseName'] as String,
    price: (json['price'] as num).toDouble(),
    recordDate: json['recordDate'] as String,
  );
}

class PriceComparison {
  const PriceComparison({
    required this.item,
    required this.cheapestOption,
    required this.prices,
  });

  final Item item;
  final CheapestOption? cheapestOption;
  final List<LatestPrice> prices;

  double? get savingDifference {
    if (prices.length < 2) return null;
    return prices.last.price - prices.first.price;
  }

  factory PriceComparison.fromJson(Map<String, dynamic> json) {
    final priceValues = json['prices'] as List<dynamic>? ?? const [];
    final prices =
        priceValues
            .map((value) => LatestPrice.fromJson(value as Map<String, dynamic>))
            .toList(growable: false)
          ..sort((first, second) => first.price.compareTo(second.price));
    final cheapest = json['cheapestOption'] as Map<String, dynamic>?;
    return PriceComparison(
      item: Item.fromJson(json['item'] as Map<String, dynamic>),
      cheapestOption: cheapest == null
          ? null
          : CheapestOption.fromJson(cheapest),
      prices: prices,
    );
  }
}
