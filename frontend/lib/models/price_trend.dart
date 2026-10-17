import 'dart:math' as math;

import 'item.dart';

class PriceTrendPoint {
  const PriceTrendPoint({
    required this.recordDate,
    required this.averagePrice,
    required this.minimumPrice,
    required this.maximumPrice,
  });

  final DateTime recordDate;
  final double averagePrice;
  final double minimumPrice;
  final double maximumPrice;

  factory PriceTrendPoint.fromJson(Map<String, dynamic> json) =>
      PriceTrendPoint(
        recordDate: DateTime.parse(json['recordDate'] as String),
        averagePrice: (json['averagePrice'] as num).toDouble(),
        minimumPrice: (json['minimumPrice'] as num).toDouble(),
        maximumPrice: (json['maximumPrice'] as num).toDouble(),
      );
}

class PriceTrend {
  const PriceTrend({required this.item, required this.points});

  final Item item;
  final List<PriceTrendPoint> points;

  double? get absoluteChange {
    if (points.length < 2) return null;
    return points.last.averagePrice - points.first.averagePrice;
  }

  double? get percentageChange {
    final change = absoluteChange;
    if (change == null || points.first.averagePrice == 0) return null;
    return change / points.first.averagePrice * 100;
  }

  double? get lowestDailyPrice => points.isEmpty
      ? null
      : points.map((point) => point.minimumPrice).reduce(math.min);

  double? get highestDailyPrice => points.isEmpty
      ? null
      : points.map((point) => point.maximumPrice).reduce(math.max);

  String get trendLabel {
    final change = absoluteChange;
    if (change == null || change.abs() < 0.005) return 'Stable';
    return change > 0 ? 'Increased' : 'Decreased';
  }

  factory PriceTrend.fromJson(Map<String, dynamic> json) {
    final trendValues = json['trends'] as List<dynamic>? ?? const [];
    final points =
        trendValues
            .map(
              (value) =>
                  PriceTrendPoint.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false)
          ..sort(
            (first, second) => first.recordDate.compareTo(second.recordDate),
          );
    return PriceTrend(
      item: Item.fromJson(json['item'] as Map<String, dynamic>),
      points: points,
    );
  }
}
