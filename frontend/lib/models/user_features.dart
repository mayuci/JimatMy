import 'item.dart';
import 'price_reliability.dart';

double? _readDouble(Object? value) => switch (value) {
  num number => number.toDouble(),
  String text => double.tryParse(text),
  _ => null,
};

int _readInt(Object? value, {int fallback = 0}) => switch (value) {
  num number => number.toInt(),
  String text => int.tryParse(text) ?? fallback,
  _ => fallback,
};

class ProfileSummary {
  const ProfileSummary({
    required this.favoriteItemCount,
    required this.historyCount,
    required this.shoppingListCount,
  });
  final int favoriteItemCount;
  final int historyCount;
  final int shoppingListCount;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) => ProfileSummary(
    favoriteItemCount: _readInt(json['favoriteItemCount']),
    historyCount: _readInt(json['historyCount']),
    shoppingListCount: _readInt(json['shoppingListCount']),
  );
}

class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.historyId,
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.itemGroup,
    required this.itemCategory,
    required this.lastViewedAt,
    this.wasCreated = false,
  });
  final String historyId;
  final int itemCode;
  final String itemName;
  final String unit;
  final String itemGroup;
  final String itemCategory;
  final DateTime? lastViewedAt;
  final bool wasCreated;

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SearchHistoryEntry(
        historyId: json['historyId'] as String,
        itemCode: _readInt(json['itemCode']),
        itemName: json['itemName'] as String,
        unit: json['unit'] as String,
        itemGroup: json['itemGroup'] as String,
        itemCategory: json['itemCategory'] as String,
        lastViewedAt: DateTime.tryParse(json['lastViewedAt'] as String? ?? ''),
        wasCreated: json['wasCreated'] as bool? ?? false,
      );
}

class FavoriteItem extends Item {
  const FavoriteItem({
    required super.itemCode,
    required super.itemName,
    required super.unit,
    required super.itemGroup,
    required super.itemCategory,
    this.favoritedAt,
    super.lowestPrice,
    super.premiseCount = 0,
    super.reliability = PriceReliability.unavailable,
  });
  final DateTime? favoritedAt;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    itemCode: _readInt(json['itemCode']),
    itemName: json['itemName'] as String,
    unit: json['unit'] as String,
    itemGroup: json['itemGroup'] as String,
    itemCategory: json['itemCategory'] as String,
    favoritedAt: DateTime.tryParse(json['favoritedAt'] as String? ?? ''),
    lowestPrice: _readDouble(json['latestLowestPrice']),
    premiseCount: _readInt(json['premiseCount']),
    reliability: PriceReliability.fromJson(
      json['reliability'] as Map<String, dynamic>?,
    ),
  );
}
